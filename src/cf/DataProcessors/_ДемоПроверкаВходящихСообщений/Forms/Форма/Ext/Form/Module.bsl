﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ЗаполнитьСписокВыбораУчетныхЗаписей();
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаКлиенте
Процедура ПроверитьВходящиеВыполнить()
	
	Если НЕ ЗначениеЗаполнено(УчетнаяЗаписьВходящие) Тогда
		ОбщегоНазначенияКлиент.СообщитьПользователю(НСтр("ru = 'Учетная запись для получения входящих не заполнена.'"));
		Возврат;
	КонецЕсли;
	
	ПроверитьВходящиеВыполнитьЗавершение();
	
КонецПроцедуры

&НаКлиенте
Процедура ПроверитьВходящиеВыполнитьЗавершение()
	
	Состояние(НСтр("ru = 'Загрузка входящих сообщений.'"),,НСтр("ru = 'Пожалуйста, подождите...'"));
	Попытка
		ЗагрузитьВходящиеСообщения();
		НовыхПисем = ВходящиеСообщения.Количество();
		Если НовыхПисем > 0 Тогда
			ПоказатьПредупреждение(, НСтр("ru = 'Получено новых писем:'") + " " + НовыхПисем);
		Иначе
			ПоказатьПредупреждение(, НСтр("ru = 'Нет новых писем.'"));
		КонецЕсли;
	Исключение
		РаботаСПочтовымиСообщениямиКлиент.СообщитьОбОшибкеПодключения(УчетнаяЗаписьВходящие, 
			НСтр("ru = 'Загрузка входящих сообщений'"), КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
	КонецПопытки;
	
КонецПроцедуры

&НаСервере
Процедура ЗагрузитьВходящиеСообщения()
	
	ПараметрыЗагрузки = Новый Структура;
	ПараметрыЗагрузки.Вставить("Колонки", "ИмяОтправителя, Вложения, Тема, ДатаОтправления, ОбратныйАдрес, Отправитель");
	
	ТаблицаВходящихСообщений = РаботаСПочтовымиСообщениями.ЗагрузитьПочтовыеСообщения(УчетнаяЗаписьВходящие, ПараметрыЗагрузки);
	
	ВходящиеСообщения.Очистить();
	
	Для Каждого ЭлементВходящееСообщение Из ТаблицаВходящихСообщений Цикл
		НоваяСтрока = ВходящиеСообщения.Добавить();
		НоваяСтрока.Отправитель     = ЭлементВходящееСообщение.ИмяОтправителя;
		Если ПустаяСтрока(ЭлементВходящееСообщение.ИмяОтправителя) Тогда
			НоваяСтрока.Отправитель     = ЭлементВходящееСообщение.Отправитель;
		КонецЕсли;
		НоваяСтрока.ОбратныйАдрес   = ЭлементВходящееСообщение.ОбратныйАдрес;
		НоваяСтрока.Тема            = ЭлементВходящееСообщение.Тема;
		НоваяСтрока.ДатаОтправления = ЭлементВходящееСообщение.ДатаОтправления;
		Если ЭлементВходящееСообщение.Вложения.Количество() > 0 Тогда
			НоваяСтрока.Вложение = Истина;
		Иначе
			НоваяСтрока.Вложение = Ложь;
		КонецЕсли
	КонецЦикла;
	
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьСписокВыбораУчетныхЗаписей()
	
	Элементы.УчетнаяЗаписьВходящие.СписокВыбора.Очистить();
	
	ДоступныеУчетныеЗаписи = РаботаСПочтовымиСообщениями.ДоступныеУчетныеЗаписи(, Истина, Истина);
	
	ЕстьПолныеУчетныеЗаписи = Ложь;
	
	Для Каждого СтрУчЗапись Из ДоступныеУчетныеЗаписи Цикл
		ЕстьПолныеУчетныеЗаписи = Истина;
		Элементы.УчетнаяЗаписьВходящие.СписокВыбора.Добавить(СтрУчЗапись.Ссылка, СтрУчЗапись.Наименование);
	КонецЦикла;
	
	Если ЕстьПолныеУчетныеЗаписи Тогда
		УчетнаяЗаписьВходящие = Элементы.УчетнаяЗаписьВходящие.СписокВыбора[0].Значение;
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти


