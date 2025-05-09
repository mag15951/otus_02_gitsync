﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

// Осуществляет переход к форме подготовки согласия на обработку персональных данных, 
// используется как клиентский обработчик печати (поэтому является функцией, а не процедурой).
//
// Параметры:
//  ПараметрыПечати - Структура - параметры обработки команды печати:
//   * ОбъектыПечати - Массив           - в первом элементе ожидается субъект персональных данных;
//   * Форма         - ФормаКлиентскогоПриложения - форма, из которой выполняется печать.
//
// Возвращаемое значение:
//   Неопределено - не требуется, т.к. функция является клиентским обработчиком печати.
//
Функция ОткрытьФормуСогласиеНаОбработкуПерсональныхДанных(ПараметрыПечати) Экспорт
	
	Если ПараметрыПечати.ОбъектыПечати.Количество() = 0 Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Субъект = ПараметрыПечати.ОбъектыПечати[0];
	ОткрытьФорму("Документ.СогласиеНаОбработкуПерсональныхДанных.ФормаОбъекта", Новый Структура("Субъект", Субъект), ПараметрыПечати.Форма);
	Возврат Неопределено;
	
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции для встраивания подсистемы в формы объектов конфигурации.

// Определяет, что указанное событие - это событие о скрытии персональных данных субъектов
// и обновляет объект управляемой формы.
//
// Параметры:
//  Форма - ФормаКлиентскогоПриложения - форма субъекта.
//  ИмяСобытия - Строка - имя обрабатываемого события.
//
Процедура ОбработкаОповещенияФормы(Форма, ИмяСобытия) Экспорт
	
	Если ИмяСобытия = "ИзмененаДатаСкрытияПерсональныхДанных" Или ИмяСобытия = "СкрытыПерсональныеДанные" Тогда
		Форма.Прочитать();
	КонецЕсли;
	
КонецПроцедуры

// Определяет, что указанное событие - это событие о скрытии персональных данных субъектов
// и обновляет данные в таблице субъектов.
//
// Параметры:
//  СписокФормы - ТаблицаФормы - элемент формы динамического списка субъектов.
//  ИмяСобытия - Строка - имя обрабатываемого события.
//
Процедура ОбработкаОповещенияФормыСписка(СписокФормы, ИмяСобытия) Экспорт
	
	Если ИмяСобытия = "ИзмененаДатаСкрытияПерсональныхДанных" Или ИмяСобытия = "СкрытыПерсональныеДанные" Тогда
		СписокФормы.Обновить();
	КонецЕсли;
	
КонецПроцедуры

// Обработчик команды формы списка субъектов персональных данных.
//
// Параметры:
//   Форма - ФормаКлиентскогоПриложения - форма субъекта.
//   Список - ДинамическийСписок - динамический список субъектов.
//
Процедура ПоказыватьСоСкрытымиПДн(Форма, Список) Экспорт
	
	Кнопка = Форма.Элементы.Найти("ПоказыватьСоСкрытымиПДн");
	Если Кнопка = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ПоказыватьСоСкрытымиПДн = Не Кнопка.Пометка;
	
	Кнопка.Пометка = ПоказыватьСоСкрытымиПДн;
	Список.Параметры.УстановитьЗначениеПараметра("ПоказыватьСоСкрытымиПДн", ПоказыватьСоСкрытымиПДн);
	
	ЗащитаПерсональныхДанныхВызовСервера.СохранитьПоложениеОтбораПоказыватьСоСкрытымиПДн(
		Форма.ИмяФормы, ПоказыватьСоСкрытымиПДн);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Настраивает элементы формы НастройкиПользователейИПрав обработки ПанельАдминистрированияБСП.
// Запускает фоновое изменение настроек скрытия персональных данных.
//
// Параметры:
//  Форма - ФормаКлиентскогоПриложения - настраиваемая форма.
//
Процедура НастройкиСкрытияПерсональныхДанныхПриИзменении(Форма) Экспорт
	
	Элементы = Форма.Элементы;
	НаборКонстант = Форма.НаборКонстант;
	
	ПараметрыВыполнения = Новый Структура;
	ПараметрыВыполнения.Вставить("ДнейДоСкрытияПерсональныхДанных", НаборКонстант.ДнейДоСкрытияПерсональныхДанныхСубъектов);
	ПараметрыВыполнения.Вставить("ИспользоватьСкрытиеПерсональныхДанных", НаборКонстант.ИспользоватьСкрытиеПерсональныхДанныхСубъектов);
	
	ФоновоеЗадание = ЗащитаПерсональныхДанныхВызовСервера.ЗапуститьИзменениеНастроекСкрытияПДнВФоновомЗадании(Форма.УникальныйИдентификатор, ПараметрыВыполнения);
	
	ДоступностьЭлементов = Новый Соответствие;
	ДоступностьЭлементов.Вставить(Элементы.ИспользоватьСкрытиеПерсональныхДанных.Имя, Элементы.ИспользоватьСкрытиеПерсональныхДанных.Доступность);
	ДоступностьЭлементов.Вставить(Элементы.ДнейДоСкрытияПерсональныхДанныхСубъектов.Имя, Элементы.ДнейДоСкрытияПерсональныхДанныхСубъектов.Доступность);
	
	Если ФоновоеЗадание <> Неопределено
		И ФоновоеЗадание.Статус = "Выполняется" Тогда
		
		Элементы.ИспользоватьСкрытиеПерсональныхДанных.Доступность = Ложь;
		Элементы.ДнейДоСкрытияПерсональныхДанныхСубъектов.Доступность = Ложь;
		
		Элементы.ДекорацияОжиданиеИзмененияИспользованияСкрытияПДн.Видимость = Истина;
		
	КонецЕсли;
	
	ДополнительныеПараметры = ДополнительныеПараметрыИзмененияНастроекСкрытияПерсональныхДанных(Форма, ДоступностьЭлементов);
	
	НастройкиОжидания = ДлительныеОперацииКлиент.ПараметрыОжидания(Форма);
	НастройкиОжидания.ВыводитьОкноОжидания = Ложь;
	
	Обработчик = Новый ОписаниеОповещения("ПослеИзмененияНастроекСкрытияПерсональныхДанных", ЭтотОбъект, ДополнительныеПараметры);
	ДлительныеОперацииКлиент.ОжидатьЗавершение(ФоновоеЗадание, Обработчик, НастройкиОжидания);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Параметры:
//   ФоновоеЗадание
//   ДополнительныеПараметры - см. ДополнительныеПараметрыИзмененияНастроекСкрытияПерсональныхДанных
//
Процедура ПослеИзмененияНастроекСкрытияПерсональныхДанных(ФоновоеЗадание, ДополнительныеПараметры) Экспорт
	
	Форма = ДополнительныеПараметры.Форма;
	ДоступностьЭлементов = ДополнительныеПараметры.ДоступностьЭлементов;
	
	Элементы = Форма.Элементы; 
	НаборКонстант = Форма.НаборКонстант;
	
	Для Каждого КлючИЗначение Из ДоступностьЭлементов Цикл
		
		ИмяЭлемента = КлючИЗначение.Ключ;
		ДоступностьДо = КлючИЗначение.Значение;
		ТекущийЭлемент = Элементы.Найти(ИмяЭлемента);
		
		Если ТекущийЭлемент.Доступность <> ДоступностьДо Тогда
			ТекущийЭлемент.Доступность = ДоступностьДо;
		КонецЕсли;
		
	КонецЦикла;
		
	Если Элементы.ДекорацияОжиданиеИзмененияИспользованияСкрытияПДн.Видимость Тогда
		Элементы.ДекорацияОжиданиеИзмененияИспользованияСкрытияПДн.Видимость = Ложь;
	КонецЕсли;
	
	Если ФоновоеЗадание <> Неопределено
		И ФоновоеЗадание.Статус = "Выполнено" Тогда
		
		Оповестить("Запись_НаборКонстант", Новый Структура, "ИспользоватьСкрытиеПерсональныхДанныхСубъектов");
		ПоказатьОповещениеПользователя(НСтр("ru = 'Настройки скрытия персональных данных изменены.'"));
		
	Иначе
		
		СтарыеНастройкиСистемы = ЗащитаПерсональныхДанныхВызовСервера.НастройкиСкрытияПерсональныхДанныхСистемы();
		
		НаборКонстант.ИспользоватьСкрытиеПерсональныхДанныхСубъектов = СтарыеНастройкиСистемы.ИспользоватьСкрытиеПерсональныхДанных;
		НаборКонстант.ДнейДоСкрытияПерсональныхДанныхСубъектов = СтарыеНастройкиСистемы.ДнейДоСкрытияПерсональныхДанных;
		
		Если ФоновоеЗадание <> Неопределено Тогда
			ТекстОшибки = НСтр("ru = 'Не удалось изменить настройки скрытия персональных данных.
				|См. подробности в журнале регистрации.'");
			ОбщегоНазначенияКлиент.СообщитьПользователю(ТекстОшибки);
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

// Возвращаемое значение:
//   Структура:
//   * ДоступностьЭлементов - Соответствие
//   * Форма - ФормаКлиентскогоПриложения
//
Функция ДополнительныеПараметрыИзмененияНастроекСкрытияПерсональныхДанных(Форма, ДоступностьЭлементов)
	ДополнительныеПараметры = Новый Структура;
	ДополнительныеПараметры.Вставить("Форма", Форма);
	ДополнительныеПараметры.Вставить("ДоступностьЭлементов", ДоступностьЭлементов);
	Возврат ДополнительныеПараметры
КонецФункции

#КонецОбласти
