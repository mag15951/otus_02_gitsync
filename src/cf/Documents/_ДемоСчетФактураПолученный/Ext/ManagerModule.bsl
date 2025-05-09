﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

#Область ДляВызоваИзДругихПодсистем

// СтандартныеПодсистемы.УправлениеДоступом

// Параметры:
//   Ограничение - см. УправлениеДоступомПереопределяемый.ПриЗаполненииОграниченияДоступа.Ограничение.
//
Процедура ПриЗаполненииОграниченияДоступа(Ограничение) Экспорт
	
	Ограничение.Текст =
	"РазрешитьЧтениеИзменение
	|ГДЕ
	|	ЗначениеРазрешено(Продавец.Партнер)";
	
КонецПроцедуры

// Конец СтандартныеПодсистемы.УправлениеДоступом

#КонецОбласти

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Проводит непроведенные документы _ДемоСчетФактураПолученный. Вызывается из обработчика исправления проблемы 
// непроведенных документов, см. _ДемоСтандартныеПодсистемыКлиент.ПровестиСчетаФактурыПоПроблемнымКонтрагентам.
// Такие документы выявляются проверкой _ДемоСтандартныеПодсистемы.ПроверитьПроведенностьСчетаФактурыПолученного.
//
// Параметры:
//    ПараметрыПроверки - Структура:
//        * ВидПроверки - СправочникСсылка.ВидыПроверок - вид осуществляемой проверки.
//    АдресХранилища - Строка - адрес временного хранилища для возвращаемого значения.
//
Процедура ПровестиСчетаФактурыПоПроблемнымКонтрагентам(Знач ПараметрыПроверки, АдресХранилища = Неопределено) Экспорт
	
	ВидПроверки = ПараметрыПроверки.ВидПроверки;
	
	НачатьТранзакцию();
	Попытка
		
		ПравилоПроверки = КонтрольВеденияУчета.ПроверкаПоИдентификатору("Демо.ПроверитьПроведенностьСчетаФактурыПолученного");
		
		БлокировкаДанных = Новый БлокировкаДанных;
		ЭлементБлокировки = БлокировкаДанных.Добавить("РегистрСведений.РезультатыПроверкиУчета");
		ЭлементБлокировки.УстановитьЗначение("ПравилоПроверки", ПравилоПроверки);
		ЭлементБлокировки.УстановитьЗначение("ВидПроверки", ВидПроверки);
		ЭлементБлокировки.УстановитьЗначение("ИгнорироватьПроблему", Ложь);
		ЭлементБлокировки.Режим = РежимБлокировкиДанных.Разделяемый;
		
		ЭлементБлокировкиВидаПроверки = БлокировкаДанных.Добавить("Справочник.ВидыПроверок");
		ЭлементБлокировкиВидаПроверки.УстановитьЗначение("Ссылка", ВидПроверки);
		ЭлементБлокировкиВидаПроверки.Режим = РежимБлокировкиДанных.Разделяемый;
		
		БлокировкаДанных.Заблокировать();
		
		Запрос = Новый Запрос(
		"ВЫБРАТЬ ПЕРВЫЕ 1000
		|	РезультатыПроверкиУчета.ПроблемныйОбъект КАК ПроблемныйОбъект
		|ИЗ
		|	РегистрСведений.РезультатыПроверкиУчета КАК РезультатыПроверкиУчета
		|ГДЕ
		|	РезультатыПроверкиУчета.ПравилоПроверки = &ПравилоПроверки
		|	И НЕ РезультатыПроверкиУчета.ИгнорироватьПроблему
		|	И РезультатыПроверкиУчета.ПроблемныйОбъект > &ПроблемныйОбъект
		|	И &УсловиеПоКонтрагенту
		|
		|УПОРЯДОЧИТЬ ПО
		|	РезультатыПроверкиУчета.ПроблемныйОбъект");
		
		Запрос.УстановитьПараметр("ПравилоПроверки",  ПравилоПроверки);
		Запрос.УстановитьПараметр("ПроблемныйОбъект", "");
		
		Контрагент = ВидПроверки.Свойство2;
		Если Контрагент = Неопределено Или Не ЗначениеЗаполнено(Контрагент) Тогда
			Запрос.Текст = СтрЗаменить(Запрос.Текст, "&УсловиеПоКонтрагенту", "Истина");
		Иначе
			Запрос.Текст = СтрЗаменить(Запрос.Текст, "&УсловиеПоКонтрагенту",
				"ВЫРАЗИТЬ(РезультатыПроверкиУчета.ВидПроверки.Свойство2 КАК Справочник._ДемоКонтрагенты) = &Контрагент");
			Запрос.УстановитьПараметр("Контрагент", Контрагент);
		КонецЕсли;
		
		Результат = Запрос.Выполнить().Выгрузить();
		
		ЗафиксироватьТранзакцию();
		
	Исключение
		
		ОтменитьТранзакцию();
		ЗаписьЖурналаРегистрации(НСтр("ru = 'Исправление счетов фактур'", ОбщегоНазначения.КодОсновногоЯзыка()), 
			УровеньЖурналаРегистрации.Ошибка,,, ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		
		ВызватьИсключение;
		
	КонецПопытки;
	
	ПодробнаяИнформацияПоПроблемам = Новый Соответствие;
	
	КоличествоПроведенных            = 0;
	КоличествоНепроведенных          = 0;
	КоличествоНеправильноЗаполненных = 0;
	
	Пока Результат.Количество() > 0 Цикл
		
		Для Каждого СтрокаРезультата Из Результат Цикл
			
			ДокументСсылка = СтрокаРезультата.ПроблемныйОбъект;
			НачатьТранзакцию();
			
			Попытка
				
				БлокировкаДанных = Новый БлокировкаДанных;
				ЭлементБлокировки = БлокировкаДанных.Добавить("Документ._ДемоСчетФактураПолученный");
				ЭлементБлокировки.УстановитьЗначение("Ссылка", ДокументСсылка);
				БлокировкаДанных.Заблокировать();
				
				ДокументОбъект = ДокументСсылка.ПолучитьОбъект();
				
				Если ДокументОбъект = Неопределено Или ДокументОбъект.Проведен Тогда
					ОтменитьТранзакцию();
					Продолжить;
				КонецЕсли;
				
				Если Не ДокументОбъект.ПроверитьЗаполнение() Тогда
					
					ОтменитьТранзакцию();
					ПодробнаяИнформацияПоПроблемам.Вставить(ДокументСсылка, ОшибкиЗаполненияОбъекта());
					КоличествоНеправильноЗаполненных = КоличествоНеправильноЗаполненных + 1;
					
					Продолжить;
					
				КонецЕсли;
				
				ДокументОбъект.Записать(РежимЗаписиДокумента.Проведение);
				КоличествоПроведенных = КоличествоПроведенных + 1;
				ЗафиксироватьТранзакцию();
				
			Исключение
				
				ОтменитьТранзакцию();
				ПодробнаяИнформацияПоПроблемам.Вставить(ДокументСсылка, ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
				КоличествоНепроведенных = КоличествоНепроведенных + 1;
				
			КонецПопытки;
			
		КонецЦикла;
		
		Запрос.УстановитьПараметр("ПроблемныйОбъект", ДокументСсылка);
		Результат = Запрос.Выполнить().Выгрузить();
		
	КонецЦикла;
	
	ИтоговыйРезультат = Новый Структура;
	ИтоговыйРезультат.Вставить("КоличествоПроведенных",            КоличествоПроведенных);
	ИтоговыйРезультат.Вставить("КоличествоНепроведенных",          КоличествоНепроведенных);
	ИтоговыйРезультат.Вставить("КоличествоНеправильноЗаполненных", КоличествоНеправильноЗаполненных);
	ИтоговыйРезультат.Вставить("ПодробнаяИнформацияПоПроблемам",   ПодробнаяИнформацияПоПроблемам);
	
	ПоместитьВоВременноеХранилище(ИтоговыйРезультат, АдресХранилища);
	
КонецПроцедуры

Функция ОшибкиЗаполненияОбъекта()
	
	УточнениеПроблемы = "";
	Для Каждого ПользовательскоеСообщение Из ПолучитьСообщенияПользователю(Истина) Цикл
		УточнениеПроблемы = УточнениеПроблемы + ?(ЗначениеЗаполнено(УточнениеПроблемы), Символы.ПС, "") + ПользовательскоеСообщение.Текст;
	КонецЦикла;
	
	Возврат ?(ПустаяСтрока(УточнениеПроблемы), НСтр("ru = 'Для подробной информации откройте форму объекта.'"), УточнениеПроблемы);
	
КонецФункции

#КонецОбласти
	
#КонецЕсли
