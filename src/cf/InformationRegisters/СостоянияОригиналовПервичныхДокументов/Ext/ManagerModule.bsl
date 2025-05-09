﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Делает записи состояний оригиналов печатных форм регистр, после печати формы.
//
//	Параметры:
//  ОбъектыПечати - СписокЗначений - список документов.
//  ПечатныеФормы - СписокЗначений - наименование макетов и представление печатных форм.
//  Записано - Булево - признак того, что состояние документа записано в регистр.
//
Процедура ЗаписатьСостоянияОригиналовДокументаПослеПечатиФормы(ОбъектыПечати, ПечатныеФормы, Записано = Ложь) Экспорт
	
	Состояние = ПредопределенноеЗначение("Справочник.СостоянияОригиналовПервичныхДокументов.ФормаНапечатана");
	Если ЗначениеЗаполнено(ОбъектыПечати) Тогда
		Если ОбъектыПечати.Количество() > 1 Тогда
			Если ПечатныеФормы.Количество() > 1 Тогда
				Для Каждого Документ Из ОбъектыПечати Цикл
					Если УчетОригиналовПервичныхДокументов.ЭтоОбъектУчета(Документ.Значение) Тогда
					// Записываем общее состояние
						ЗаписатьОбщееСостояниеОригиналаДокумента(Документ.Значение,Состояние);
						ТЧ = УчетОригиналовПервичныхДокументов.ТабличнаяЧастьМногосотрудниковаДокумента(Документ.Значение); 
						Если ТЧ <> "" Тогда
							Для Каждого Сотрудник Из Документ.Значение[ТЧ] Цикл
								Для Каждого Форма Из ПечатныеФормы Цикл //Если документов и форм несколько, записываем для каждого документа, состояние каждой формы
									ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ.Значение, Форма.Значение, Форма.Представление, Состояние, Ложь, Сотрудник.Сотрудник);
								КонецЦикла;
							КонецЦикла;
						Иначе
							Для Каждого Форма Из ПечатныеФормы Цикл //Если документов и форм несколько, записываем для каждого документа, состояние каждой формы
								ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ.Значение, Форма.Значение, Форма.Представление, Состояние, Ложь);
							КонецЦикла;
						КонецЕсли;
						Записано = Истина;
					КонецЕсли;
				КонецЦикла;
			Иначе
				Для Каждого Документ Из ОбъектыПечати Цикл
					Если УчетОригиналовПервичныхДокументов.ЭтоОбъектУчета(Документ.Значение) Тогда
						ТЧ = УчетОригиналовПервичныхДокументов.ТабличнаяЧастьМногосотрудниковаДокумента(Документ.Значение); 
						Если ТЧ <> "" Тогда
							Для Каждого Сотрудник Из Документ.Значение[ТЧ] Цикл
								ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ.Значение, ПечатныеФормы[0].Значение,ПечатныеФормы[0].Представление, Состояние, Ложь,Сотрудник.Сотрудник);
							КонецЦикла;
						Иначе
							ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ.Значение, ПечатныеФормы[0].Значение,ПечатныеФормы[0].Представление, Состояние, Ложь);	
						КонецЕсли;
					ЗаписатьОбщееСостояниеОригиналаДокумента(Документ.Значение,Состояние);
					Записано = Истина;
					КонецЕсли;
				КонецЦикла;
			КонецЕсли;
		Иначе
			Документ = ОбъектыПечати[0].Значение;
			Если УчетОригиналовПервичныхДокументов.ЭтоОбъектУчета(Документ) Тогда
				Если ПечатныеФормы.Количество() > 1 Тогда
					ТЧ = УчетОригиналовПервичныхДокументов.ТабличнаяЧастьМногосотрудниковаДокумента(Документ); 
					Если ТЧ <> "" Тогда
						Для Каждого Сотрудник Из Документ[ТЧ] Цикл
							Для Каждого Форма Из ПечатныеФормы Цикл
								ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ, Форма.Значение,Форма.Представление, Состояние, Ложь,Сотрудник.Сотрудник);
							КонецЦикла;
						КонецЦикла;
					Иначе
						Для Каждого Форма Из ПечатныеФормы Цикл
							ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ, Форма.Значение,Форма.Представление, Состояние, Ложь);
						КонецЦикла;
					КонецЕсли;
				Иначе
					ТЧ = УчетОригиналовПервичныхДокументов.ТабличнаяЧастьМногосотрудниковаДокумента(Документ); 
					Если ТЧ <> "" Тогда
						Для Каждого Сотрудник Из Документ[ТЧ] Цикл
							ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ, ПечатныеФормы[0].Значение,ПечатныеФормы[0].Представление, Состояние, Ложь, Сотрудник.Сотрудник);
						КонецЦикла;
					Иначе
						ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ, ПечатныеФормы[0].Значение,ПечатныеФормы[0].Представление, Состояние, Ложь);
					КонецЕсли;
				КонецЕсли;
				ЗаписатьОбщееСостояниеОригиналаДокумента(Документ,Состояние);
				Записано = Истина;
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

// Делает запись состояния оригинала печатной формы в регистр, после печати формы.
//
//	Параметры:
//  Документ - ДокументСсылка - ссылка на документ.
//  ПечатнаяФорма - Строка - имя макета печатной формы.
//  Представление - Строка - наименование печатной формы.
//  Состояние - Строка - наименование состояния оригинала печатной формы
//            - СправочникСсылка - ссылка на состояние оригинала печатной формы.
//  Извне - Булево - признак, показывающий принадлежит ли форма системе 1С.
//  Сотрудник - СправочникСсылка - ссылка на сотрудника, если оригинал документа является многосотрудниковым.
//
Процедура ЗаписатьСостояниеОригиналаДокументаПоПечатнымФормам(Документ, ПечатнаяФорма, Представление, Состояние, Извне, Сотрудник = Неопределено) Экспорт
	
УстановитьПривилегированныйРежим(Истина);
	
	НачатьТранзакцию();
	
	Попытка

		ЗаписьСостоянияОригинала = РегистрыСведений.СостоянияОригиналовПервичныхДокументов.СоздатьМенеджерЗаписи();
		ЗаписьСостоянияОригинала.Владелец = Документ.Ссылка;
		ЗаписьСостоянияОригинала.ПервичныйДокумент = ПечатнаяФорма;
		Если ЗначениеЗаполнено(Сотрудник) Тогда
			ФИО = Сотрудник.Наименование;
			// Локализация
			МодульФизическиеЛицаКлиентСервер = ОбщегоНазначения.ОбщийМодуль("ФизическиеЛицаКлиентСервер");
			Если МодульФизическиеЛицаКлиентСервер <> Неопределено Тогда
				ФИО = МодульФизическиеЛицаКлиентСервер.ФамилияИнициалы(Сотрудник.Наименование);
			Иначе
				ФИО = Сотрудник.Наименование;
			КонецЕсли;
			// Конец Локализация
			Значения = Новый Структура("Представление, ФИО", Представление, ФИО);
			ПредставлениеСотрудник = СтрНайти(Представление, ФИО);
			Если ПредставлениеСотрудник = 0 Тогда
				ЗаписьСостоянияОригинала.ПервичныйДокументПредставление = СтроковыеФункцииКлиентСервер.ВставитьПараметрыВСтроку(НСтр("ru='[Представление] [ФИО]'"), Значения);
			Иначе
				ЗаписьСостоянияОригинала.ПервичныйДокументПредставление = Представление;
			КонецЕсли;
		Иначе
			ЗаписьСостоянияОригинала.ПервичныйДокументПредставление = Представление;
		КонецЕсли;
		ЗаписьСостоянияОригинала.Состояние = Справочники.СостоянияОригиналовПервичныхДокументов.НайтиПоНаименованию(Состояние);
		ЗаписьСостоянияОригинала.АвторИзменения = Пользователи.АвторизованныйПользователь();
		ЗаписьСостоянияОригинала.ОбщееСостояние = Ложь;
		ЗаписьСостоянияОригинала.ФормаИзвне = Извне;
		ЗаписьСостоянияОригинала.ДатаПоследнегоИзменения = ТекущаяДатаСеанса();
		ЗаписьСостоянияОригинала.Сотрудник = Сотрудник;
		ЗаписьСостоянияОригинала.Записать();
		
		ЗафиксироватьТранзакцию();
		
	Исключение	
		
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;

	УстановитьПривилегированныйРежим(Ложь);

КонецПроцедуры

// Делает запись общего состояния оригинала документа в регистр.
//
//	Параметры:
//  Документ - ДокументСсылка - ссылка на документ.
//  Состояние - Строка - наименование состояния оригинала.
//
Процедура ЗаписатьОбщееСостояниеОригиналаДокумента(Документ, Состояние) Экспорт

	УстановитьПривилегированныйРежим(Истина);
	
	НачатьТранзакцию();
	
	Попытка
		
		Блокировка = Новый БлокировкаДанных();
		Элемент = Блокировка.Добавить("РегистрСведений.СостоянияОригиналовПервичныхДокументов");
		Элемент.Режим = РежимБлокировкиДанных.Исключительный;
		Блокировка.Заблокировать();

		ЗаписьСостоянияОригинала = РегистрыСведений.СостоянияОригиналовПервичныхДокументов.СоздатьМенеджерЗаписи();
		ЗаписьСостоянияОригинала.Владелец = Документ.Ссылка;
		ЗаписьСостоянияОригинала.ПервичныйДокумент = "";
		
		ПроверкаЗаписьСостоянияОригинала = РегистрыСведений.СостоянияОригиналовПервичныхДокументов.СоздатьНаборЗаписей();
		ПроверкаЗаписьСостоянияОригинала.Отбор.Владелец.Установить(Документ.Ссылка);
		ПроверкаЗаписьСостоянияОригинала.Отбор.ОбщееСостояние.Установить(Ложь);
		ПроверкаЗаписьСостоянияОригинала.Прочитать();
		Если ПроверкаЗаписьСостоянияОригинала.Количество() > 1 Тогда
			Для Каждого Запись Из ПроверкаЗаписьСостоянияОригинала Цикл
				Если Запись.АвторИзменения <> Пользователи.ТекущийПользователь() Тогда
					ЗаписьСостоянияОригинала.АвторИзменения = Неопределено;
				Иначе
					ЗаписьСостоянияОригинала.АвторИзменения = Пользователи.ТекущийПользователь();
				КонецЕсли;
			КонецЦикла;
		Иначе
			ЗаписьСостоянияОригинала.АвторИзменения = Пользователи.ТекущийПользователь();
		КонецЕсли;
		
		Если ПроверкаЗаписьСостоянияОригинала.Количество() > 0 Тогда
			Если УчетОригиналовПервичныхДокументов.СостояниеПечатныхФормОдинаково(Документ,Состояние) Тогда
				ЗаписьСостоянияОригинала.Состояние = Справочники.СостоянияОригиналовПервичныхДокументов.НайтиПоНаименованию(Состояние);
			Иначе
				ЗаписьСостоянияОригинала.Состояние = Справочники.СостоянияОригиналовПервичныхДокументов.ОригиналыНеВсе;
			КонецЕсли;
		Иначе
			ЗаписьСостоянияОригинала.Состояние = Справочники.СостоянияОригиналовПервичныхДокументов.НайтиПоНаименованию(Состояние);
		КонецЕсли;
		

		ЗаписьСостоянияОригинала.ОбщееСостояние = Истина;
		ЗаписьСостоянияОригинала.ДатаПоследнегоИзменения = ТекущаяДатаСеанса();
		ЗаписьСостоянияОригинала.Записать();
		
		ЗафиксироватьТранзакцию();
		
	Исключение	
		
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;

	УстановитьПривилегированныйРежим(Ложь);

КонецПроцедуры

#КонецОбласти

#КонецЕсли

