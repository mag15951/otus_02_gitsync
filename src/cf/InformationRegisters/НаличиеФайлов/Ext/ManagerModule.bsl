﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область СлужебныйПрограммныйИнтерфейс

////////////////////////////////////////////////////////////////////////////////
// Обработчики обновления.

// Регистрирует на плане обмена ОбновлениеИнформационнойБазы объекты,
// для которых необходимо обновить записи в регистре.
//
Процедура ЗарегистрироватьДанныеКОбработкеДляПереходаНаНовуюВерсию(Параметры) Экспорт
	
	ОтработаныВсеВладельцыФайлов = Ложь;
	Ссылка = "";
	Пока Не ОтработаныВсеВладельцыФайлов Цикл
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ РАЗЛИЧНЫЕ ПЕРВЫЕ 1000
			|	Файлы.Ссылка КАК Ссылка
			|ИЗ
			|	Справочник.Файлы КАК Файлы
			|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.НаличиеФайлов КАК НаличиеФайлов
			|		ПО Файлы.ВладелецФайла = НаличиеФайлов.ОбъектСФайлами
			|ГДЕ
			|	НаличиеФайлов.ОбъектСФайлами ЕСТЬ NULL 
			|	И Файлы.Ссылка > &Ссылка
			|
			|УПОРЯДОЧИТЬ ПО
			|	Ссылка";
			
		Запрос.УстановитьПараметр("Ссылка", Ссылка);
		МассивСсылок = Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("Ссылка"); 
	
		ОбновлениеИнформационнойБазы.ОтметитьКОбработке(Параметры, МассивСсылок);
		
		КоличествоСсылок = МассивСсылок.Количество();
		Если КоличествоСсылок < 1000 Тогда
			ОтработаныВсеВладельцыФайлов = Истина;
		КонецЕсли;
		
		Если КоличествоСсылок > 0 Тогда
			Ссылка = МассивСсылок[КоличествоСсылок-1];
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

// Обновить записи регистра.
Процедура ОбработатьДанныеДляПереходаНаНовуюВерсию(Параметры) Экспорт
	
	ОбработкаЗавершена = Истина;
	
	Выборка = ОбновлениеИнформационнойБазы.ВыбратьСсылкиДляОбработки(Параметры.Очередь, "Справочник.Файлы");
	
	ОбъектовОбработано = 0;
	ПроблемныхОбъектов = 0;
	
	Пока Выборка.Следующий() Цикл
		
		ВладелецФайла = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(Выборка.Ссылка, "ВладелецФайла");
		Если НЕ ЗначениеЗаполнено(ВладелецФайла) Тогда
			ОбновлениеИнформационнойБазы.ОтметитьВыполнениеОбработки(Выборка.Ссылка);
			Продолжить;
		КонецЕсли;
		
		НачатьТранзакцию();
		Попытка
			
			Блокировка = Новый БлокировкаДанных;
			ЭлементБлокировки = Блокировка.Добавить("Справочник.Файлы");
			ЭлементБлокировки.УстановитьЗначение("Ссылка", Выборка.Ссылка);
			ЭлементБлокировки.Режим = РежимБлокировкиДанных.Разделяемый;
			Блокировка.Заблокировать();
			
			НаборЗаписейНаличиеФайлов = СоздатьНаборЗаписей();
			НаборЗаписейНаличиеФайлов.Отбор.ОбъектСФайлами.Установить(ВладелецФайла);
			
			ЗаписьНабораНаличиеФайлов                      = НаборЗаписейНаличиеФайлов.Добавить();
			ЗаписьНабораНаличиеФайлов.ОбъектСФайлами       = ВладелецФайла;
			ЗаписьНабораНаличиеФайлов.ЕстьФайлы            = Истина;
			ЗаписьНабораНаличиеФайлов.ИдентификаторОбъекта = РаботаСФайламиСлужебный.ПолучитьОчереднойИдентификаторОбъекта();
			ОбновлениеИнформационнойБазы.ЗаписатьНаборЗаписей(НаборЗаписейНаличиеФайлов, Истина);
			
			ОбновлениеИнформационнойБазы.ОтметитьВыполнениеОбработки(Выборка.Ссылка);
			ОбъектовОбработано = ОбъектовОбработано + 1;
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			// Если не удалось обработать какой-либо документ, повторяем попытку снова.
			ПроблемныхОбъектов = ПроблемныхОбъектов + 1;
			
			ТекстСообщения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = 'Не удалось обработать сведения о наличие файлов %1 по причине:
					|%2'"), 
				Выборка.Ссылка, ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
			ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(), УровеньЖурналаРегистрации.Предупреждение,
				Выборка.Ссылка.Метаданные(), Выборка.Ссылка, ТекстСообщения);
		КонецПопытки;
		
	КонецЦикла;
	
	Если Не ОбновлениеИнформационнойБазы.ОбработкаДанныхЗавершена(Параметры.Очередь, "Справочник.Файлы") Тогда
		ОбработкаЗавершена = Ложь;
	КонецЕсли;
	
	Если ОбъектовОбработано = 0 И ПроблемныхОбъектов <> 0 Тогда
		ТекстСообщения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Не удалось обработать сведения о наличие файлов (пропущены): %1'"), 
			ПроблемныхОбъектов);
		ВызватьИсключение ТекстСообщения;
	Иначе
		ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(), 
			УровеньЖурналаРегистрации.Информация, , ,
			СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = 'Обработана очередная порция сведений о наличие файлов: %1'"),
				ОбъектовОбработано));
	КонецЕсли;
	
	Параметры.ОбработкаЗавершена = ОбработкаЗавершена;
	
КонецПроцедуры

#КонецОбласти

#КонецЕсли

