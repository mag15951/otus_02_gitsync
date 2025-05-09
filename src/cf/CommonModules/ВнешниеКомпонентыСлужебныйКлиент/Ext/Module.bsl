﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область СлужебныйПрограммныйИнтерфейс

Процедура ПроверитьМестоположениеКомпоненты(Идентификатор, Местоположение) Экспорт
	
	Если СтрНачинаетсяС(Местоположение, "e1cib/data/Справочник.ВнешниеКомпоненты.ХранилищеКомпоненты") Тогда
		Возврат;
	КонецЕсли;
	
	Если ОбщегоНазначенияКлиент.ПодсистемаСуществует("СтандартныеПодсистемы.РаботаВМоделиСервиса.ВнешниеКомпонентыВМоделиСервиса") Тогда
		МодульВнешниеКомпонентыВМоделиСервисаСлужебныйКлиент = ОбщегоНазначенияКлиент.ОбщийМодуль("ВнешниеКомпонентыВМоделиСервисаСлужебныйКлиент");
		Если МодульВнешниеКомпонентыВМоделиСервисаСлужебныйКлиент.ЭтоКомпонентаИзХранилища(Местоположение) Тогда
			Возврат;
		КонецЕсли;
	КонецЕсли;
	
	ВызватьИсключение СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Не удалось подключить внешнюю компоненту ""%1"" в клиентском приложении
		           |по причине:
		           |указано некорректное местоположение внешней компоненты
		           |%2'"),
		Идентификатор, Местоположение);

КонецПроцедуры

// Параметры:
//  Оповещение - ОписаниеОповещения
//  Контекст - см. ОбщегоНазначенияСлужебныйКлиент.КонтекстПодключенияКомпоненты
//
Процедура ПроверитьДоступностьКомпоненты(Оповещение, Контекст) Экспорт
	
	ПутьКМакетуДляПоискаПоследнейВерсии = Неопределено;
	ИскатьКомпонентуПоследнейВерсии = ЗначениеЗаполнено(Контекст.ИсходноеМестоположение) И НЕ Контекст.ВыполненПоискНовойВерсии; 
	Если ИскатьКомпонентуПоследнейВерсии Тогда
		ПутьКМакетуДляПоискаПоследнейВерсии = Контекст.ИсходноеМестоположение;
	КонецЕсли;
	
	Информация = ВнешниеКомпонентыСлужебныйВызовСервера.ИнформацияОСохраненнойКомпоненте(
		Контекст.Идентификатор, Контекст.Версия, ПутьКМакетуДляПоискаПоследнейВерсии);
	
	Контекст.Местоположение = Информация.Местоположение;
	
	// Информация.Состояние:
	// * НеНайдена
	// * НайденаВХранилище
	// * НайденаВОбщемХранилище
	// * ОтключенаАдминистратором
	
	Результат = РезультатДоступностиКомпоненты();
	Результат.КомпонентаПоследнейВерсии = Информация.ПоследняяВерсияКомпонентыИзМакета;
	Результат.Местоположение = Информация.Местоположение;
	
	Если Информация.Состояние = "ОтключенаАдминистратором" Тогда 
		
		Результат.ОписаниеОшибки = НСтр("ru = 'Отключена администратором.'");
		ВыполнитьОбработкуОповещения(Оповещение, Результат);
		
	ИначеЕсли Информация.Состояние = "НеНайдена" Тогда 
		
		Если Информация.ДоступнаЗагрузкаСПортала 
			И Контекст.ПредложитьЗагрузить Тогда 
			
			КонтекстПоиска = Новый Структура;
			КонтекстПоиска.Вставить("Оповещение", Оповещение);
			КонтекстПоиска.Вставить("Контекст", Контекст);
			
			ОповещениеФормы = Новый ОписаниеОповещения(
				"ПроверитьДоступностьКомпонентыПослеПоискаКомпонентыНаПортале",
				ЭтотОбъект, 
				КонтекстПоиска);
			
			ПоискКомпонентыНаПортале(ОповещениеФормы, Контекст);
			
		Иначе 
			Результат.ОписаниеОшибки = НСтр("ru = 'Компонента отсутствует в списке разрешенных внешних компонент.'");
			ВыполнитьОбработкуОповещения(Оповещение, Результат);
		КонецЕсли;
		
	Иначе
		
		Если ТекущийКлиентПоддерживаетсяКомпонентой(Информация.Реквизиты) Тогда
			
			Результат.Доступна = Истина;
			Результат.Вставить("Версия", Информация.Реквизиты.Версия);
			
			Если ИскатьКомпонентуПоследнейВерсии Тогда
				ЧастиВерсии = СтрРазделить(Результат.Версия, ".");
				Если ЧастиВерсии.Количество() = 4 Тогда
					// Версия внешней компоненты больше, чем версия макета.
					Если ОбщегоНазначенияКлиентСервер.СравнитьВерсии(Результат.Версия,
						Результат.КомпонентаПоследнейВерсии.Версия) > 0 Тогда
						Результат.КомпонентаПоследнейВерсии = Новый Структура("Идентификатор, Версия, Местоположение",
							Контекст.Идентификатор, Результат.Версия, Информация.Местоположение);
					КонецЕсли;
				Иначе
					// Если номер версии компоненты не соответствует шаблону, используется компонента из справочника.
					Результат.КомпонентаПоследнейВерсии = Новый Структура("Идентификатор, Версия, Местоположение",
						Контекст.Идентификатор, Результат.Версия, Информация.Местоположение);
				КонецЕсли;
			КонецЕсли;
			
			ВыполнитьОбработкуОповещения(Оповещение, Результат);
			
		Иначе 
			
			ОповещениеФормы = Новый ОписаниеОповещения(
				"ПроверитьДоступностьКомпонентыПослеОтображенияДоступныхВидовКлиентов",
				ЭтотОбъект,
				Оповещение);
			
			ПараметрыФормы = Новый Структура;
			ПараметрыФормы.Вставить("ТекстПояснения", Контекст.ТекстПояснения);
			ПараметрыФормы.Вставить("ПоддерживаемыеКлиенты", Информация.Реквизиты);
			
			ОткрытьФорму("ОбщаяФорма.УстановкаВнешнейКомпонентыНевозможна",
				ПараметрыФормы,,,,, ОповещениеФормы);
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

// См. СтандартныеПодсистемыКлиент.ПриПолученииСерверногоОповещения
Процедура ПриПолученииСерверногоОповещения(ИмяОповещения, Результат) Экспорт
	
	Если ИмяОповещения <> "СтандартныеПодсистемы.ВнешниеКомпоненты" Тогда
		Возврат;
	КонецЕсли;
	
	ПараметрыПриложения.Вставить("СтандартныеПодсистемы.ВнешниеКомпоненты.СимволическиеИмена",
		Новый ФиксированноеСоответствие(Новый Соответствие));
	
	ПараметрыПриложения.Вставить("СтандартныеПодсистемы.ВнешниеКомпоненты.Объекты",
		Новый ФиксированноеСоответствие(Новый Соответствие));
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

#Область ПроверитьДоступностьКомпоненты

Процедура ПроверитьДоступностьКомпонентыПослеПоискаКомпонентыНаПортале(Загружена, КонтекстПоиска) Экспорт
	
	Оповещение = КонтекстПоиска.Оповещение;
	Контекст   = КонтекстПоиска.Контекст;
	
	Если Загружена Тогда
		Контекст.ПредложитьЗагрузить = Ложь;
		ПроверитьДоступностьКомпоненты(Оповещение, Контекст);
	Иначе 
		ВыполнитьОбработкуОповещения(Оповещение, РезультатДоступностиКомпоненты());
	КонецЕсли;
	
КонецПроцедуры

Процедура ПроверитьДоступностьКомпонентыПослеОтображенияДоступныхВидовКлиентов(Результат, Оповещение) Экспорт
	
	ВыполнитьОбработкуОповещения(Оповещение, РезультатДоступностиКомпоненты());
	
КонецПроцедуры

// Возвращаемое значение:
//  Структура:
//   * Доступна - Булево
//   * Версия - Строка
//   * КомпонентаПоследнейВерсии - см. СтандартныеПодсистемыСервер.КомпонентаПоследнейВерсии
//   * ОписаниеОшибки - Строка
//   * Местоположение - Строка
//
Функция РезультатДоступностиКомпоненты() Экспорт
	
	Результат = Новый Структура;
	Результат.Вставить("Доступна", Ложь);
	Результат.Вставить("Версия", "");
	Результат.Вставить("КомпонентаПоследнейВерсии", Неопределено);
	Результат.Вставить("ОписаниеОшибки", "");
	Результат.Вставить("Местоположение", "");
	
	Возврат Результат;
	
КонецФункции

Функция ТекущийКлиентПоддерживаетсяКомпонентой(Реквизиты)
	
	СистемнаяИнформация = Новый СистемнаяИнформация;
	
	Браузер = Неопределено;
#Если ВебКлиент Тогда
	Строка = СистемнаяИнформация.ИнформацияПрограммыПросмотра;
	
	Если СтрНайти(Строка, "Chrome/") > 0 Тогда
		Браузер = "Chrome";
	ИначеЕсли СтрНайти(Строка, "MSIE") > 0 Тогда
		Браузер = "MSIE";
	ИначеЕсли СтрНайти(Строка, "Safari/") > 0 Тогда
		Браузер = "Safari";
	ИначеЕсли СтрНайти(Строка, "Firefox/") > 0 Тогда
		Браузер = "Firefox";
	КонецЕсли;
#КонецЕсли
	
	Если СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Linux_x86 Тогда
		
		Если Браузер = Неопределено Тогда
			Возврат Реквизиты.Linux_x86;
		КонецЕсли;
		
		Если Браузер = "Firefox" Тогда
			Возврат Реквизиты.Linux_x86_Firefox;
		КонецЕсли;
		
		Если Браузер = "Chrome" Тогда
			Возврат Реквизиты.Linux_x86_Chrome;
		КонецЕсли;
			
	ИначеЕсли СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Linux_x86_64 Тогда
		
		Если Браузер = Неопределено Тогда
			Возврат Реквизиты.Linux_x86_64;
		КонецЕсли;
		
		Если Браузер = "Firefox" Тогда
			Возврат Реквизиты.Linux_x86_64_Firefox;
		КонецЕсли;
		
		Если Браузер = "Chrome" Тогда
			Возврат Реквизиты.Linux_x86_64_Chrome;
		КонецЕсли;
		
	ИначеЕсли СистемнаяИнформация.ТипПлатформы = ТипПлатформы.MacOS_x86_64 Тогда
		
		Если Браузер = Неопределено Тогда
			Возврат Реквизиты.MacOS_x86_64;
		КонецЕсли;
		
		Если Браузер = "Safari" Тогда
			Возврат Реквизиты.MacOS_x86_64_Safari;
		КонецЕсли;
		
		Если Браузер = "Firefox" Тогда
			Возврат Реквизиты.MacOS_x86_64_Firefox;
		КонецЕсли;
		
		Если Браузер = "Chrome" Тогда
			Возврат Реквизиты.MacOS_x86_64_Chrome;
		КонецЕсли;
		
	ИначеЕсли СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Windows_x86 Тогда
		
		Если Браузер = Неопределено Тогда
			Возврат Реквизиты.Windows_x86;
		КонецЕсли;
		
		Если Браузер = "Firefox" Тогда
			Возврат Реквизиты.Windows_x86_Firefox;
		КонецЕсли;
		
		Если Браузер = "Chrome" Тогда
			Возврат Реквизиты.Windows_x86_Chrome;
		КонецЕсли;
		
		Если Браузер = "MSIE" Тогда
			Возврат Реквизиты.Windows_x86_MSIE;
		КонецЕсли;
		
	ИначеЕсли СистемнаяИнформация.ТипПлатформы = ТипПлатформы.Windows_x86_64 Тогда
		
		Если Браузер = Неопределено Тогда
			Возврат Реквизиты.Windows_x86_64;
		КонецЕсли;
		
		Если Браузер = "Firefox" Тогда
			Возврат Реквизиты.Windows_x86_Firefox;
		КонецЕсли;
		
		Если Браузер = "Chrome" Тогда
			Возврат Реквизиты.Windows_x86_Chrome;
		КонецЕсли;
		
		Если Браузер = "MSIE" Тогда
			Возврат Реквизиты.Windows_x86_64_MSIE;
		КонецЕсли;
	
	ИначеЕсли СистемнаяИнформация.ТипПлатформы = ТипПлатформы.MacOS_x86 Тогда
		// В браузере может быть неправильно определен тип платформы.
	
		Если Браузер = "Firefox" Тогда
			Возврат Реквизиты.MacOS_x86_64_Firefox;
		КонецЕсли;
		
		Если Браузер = "Chrome" Тогда
			Возврат Реквизиты.MacOS_x86_64_Chrome;
		КонецЕсли;
		
	КонецЕсли;
	
	Возврат Ложь;
	
КонецФункции

#КонецОбласти

#Область ПодключитьКомпоненту

Процедура ПодключитьКомпоненту(Контекст) Экспорт 
	
	Оповещение = Новый ОписаниеОповещения(
		"ПодключитьКомпонентуПослеПроверкиДоступности", 
		ЭтотОбъект, 
		Контекст);
	
	ПроверитьДоступностьКомпоненты(Оповещение, Контекст);
	
КонецПроцедуры

// Параметры:
//  Результат - Структура - результат подключения компоненты:
//    * Подключено - Булево - признак подключения;
//    * ПодключаемыйМодуль - ОбъектВнешнейКомпоненты - экземпляр объекта внешней компоненты.
//    * ОписаниеОшибки - Строка - краткое описание ошибки. При отмене пользователем пустая строка
//  Контекст - см. ОбщегоНазначенияСлужебныйКлиент.КонтекстПодключенияКомпоненты
//
Процедура ПодключитьКомпонентуПослеПроверкиДоступности(Результат, Контекст) Экспорт
	
	Если Результат.Доступна Тогда 
		ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпоненту(Контекст);
	Иначе
		Если Не ПустаяСтрока(Результат.ОписаниеОшибки) Тогда 
			ТекстОшибки = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
				           |из хранилища внешних компонент
				           |по причине:
				           |%2'"),
				Контекст.Идентификатор,
				Результат.ОписаниеОшибки);
		КонецЕсли;
		
		ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпонентуОповеститьОбОшибке(ТекстОшибки, Контекст);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ПодключитьКомпонентуИзРеестраWindows

// Возвращаемое значение:
//  Структура:
//   * Оповещение - ОписаниеОповещения
//   * Идентификатор - Строка
//   * ИдентификаторСозданияОбъекта - Строка
//
Функция КонтекстПодключенияКомпонентыИзРеестраWindows() Экспорт
	
	Контекст = Новый Структура;
	Контекст.Вставить("Оповещение", Неопределено);
	Контекст.Вставить("Идентификатор", "");
	Контекст.Вставить("ИдентификаторСозданияОбъекта", "");
	Возврат Контекст;
		
КонецФункции	

// Для вызова из ВнешниеКомпонентыКлиент.ПодключитьКомпонентуИзРеестраWindows.
// 
// Параметры:
//  Контекст - см. КонтекстПодключенияКомпонентыИзРеестраWindows.
//
Процедура ПодключитьКомпонентуИзРеестраWindows(Контекст) Экспорт
	
	Если ПодключитьКомпонентуИзРеестраWindowsДоступноПодключение() Тогда
		
		Оповещение = Новый ОписаниеОповещения(
		"ПодключитьКомпонентуИзРеестраWindowsПослеПопыткиПодключения", ЭтотОбъект, Контекст,
		"ПодключитьКомпонентуИзРеестраWindowsПриОбработкеОшибки", ЭтотОбъект);
		
		НачатьПодключениеВнешнейКомпоненты(Оповещение, "AddIn." + Контекст.Идентификатор);
		
	Иначе 
		
		ТекстОшибки = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Подключить компоненту из реестра Windows возможно только в тонком или толстом клиентах Windows.'"),
		Контекст.Идентификатор);
		
		ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпонентуОповеститьОбОшибке(ТекстОшибки, Контекст);
		
	КонецЕсли;
	
КонецПроцедуры

// Продолжение процедуры ПодключитьКомпонентуИзРеестраWindows.
//
// Параметры:
//  Подключено - Булево
//  Контекст - см. ОбщегоНазначенияСлужебныйКлиент.КонтекстПодключенияКомпоненты
//
Процедура ПодключитьКомпонентуИзРеестраWindowsПослеПопыткиПодключения(Подключено, Контекст) Экспорт
	
	Если Подключено Тогда 
		
		ИдентификаторСозданияОбъекта = Контекст.ИдентификаторСозданияОбъекта;
			
		Если ИдентификаторСозданияОбъекта = Неопределено Тогда 
			ИдентификаторСозданияОбъекта = Контекст.Идентификатор;
		КонецЕсли;
		
		Попытка
			ПодключаемыйМодуль = Новый("AddIn." + ИдентификаторСозданияОбъекта);
			Если ПодключаемыйМодуль = Неопределено Тогда 
				ВызватьИсключение НСтр("ru = 'Оператор Новый вернул Неопределено'");
			КонецЕсли;
		Исключение
			ПодключаемыйМодуль = Неопределено;
			ТекстОшибки = КраткоеПредставлениеОшибки(ИнформацияОбОшибке());
		КонецПопытки;
		
		Если ПодключаемыйМодуль = Неопределено Тогда 
			
			ТекстОшибки = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = 'Не удалось создать объект внешней компоненты ""%1"", подключенной на клиенте
				           |из реестра Windows,
				           |по причине:
				           |%2'"),
				Контекст.Идентификатор,
				ТекстОшибки);
				
			ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпонентуОповеститьОбОшибке(ТекстОшибки, Контекст);
			
		Иначе 
			ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпонентуОповеститьОПодключении(ПодключаемыйМодуль, Контекст);
		КонецЕсли;
		
	Иначе 
		
		ТекстОшибки = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из реестра Windows
			           |по причине:
			           |Метод %2 вернул %3.'"),
			Контекст.Идентификатор, "НачатьПодключениеВнешнейКомпоненты", "Ложь");
			
		ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпонентуОповеститьОбОшибке(ТекстОшибки, Контекст);
		
	КонецЕсли;
	
КонецПроцедуры

// Продолжение процедуры ПодключитьКомпонентуИзРеестраWindows.
//
// Параметры:
//  ИнформацияОбОшибке - ИнформацияОбОшибке
//  СтандартнаяОбработка - Булево
//  Контекст - см. ОбщегоНазначенияСлужебныйКлиент.КонтекстПодключенияКомпоненты
//
Процедура ПодключитьКомпонентуИзРеестраWindowsПриОбработкеОшибки(ИнформацияОбОшибке, СтандартнаяОбработка, Контекст) Экспорт
	
	СтандартнаяОбработка = Ложь;
	
	ТекстОшибки = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
		           |из реестра Windows
		           |по причине:
		           |%2'"),
		Контекст.Идентификатор,
		КраткоеПредставлениеОшибки(ИнформацияОбОшибке));
		
	ОбщегоНазначенияСлужебныйКлиент.ПодключитьКомпонентуОповеститьОбОшибке(ТекстОшибки, Контекст);
	
КонецПроцедуры

// Продолжение процедуры ПодключитьКомпонентуИзРеестраWindows.
Функция ПодключитьКомпонентуИзРеестраWindowsДоступноПодключение()
	
#Если ВебКлиент Тогда
	Возврат Ложь;
#Иначе
	Возврат ОбщегоНазначенияКлиент.ЭтоWindowsКлиент();
#КонецЕсли
	
КонецФункции

#КонецОбласти

#Область УстановитьКомпоненту

Процедура УстановитьКомпоненту(Контекст) Экспорт
	
	Оповещение = Новый ОписаниеОповещения(
		"УстановитьКомпонентуПослеПроверкиДоступности", 
		ЭтотОбъект, 
		Контекст);
	
	ПроверитьДоступностьКомпоненты(Оповещение, Контекст);
	
КонецПроцедуры

// Параметры:
//  Результат - Структура - результат подключения компоненты:
//    * Подключено - Булево - признак подключения;
//    * ПодключаемыйМодуль - ОбъектВнешнейКомпоненты - экземпляр объекта внешней компоненты.
//    * ОписаниеОшибки - Строка - краткое описание ошибки. При отмене пользователем пустая строка.
//  Контекст - см. ОбщегоНазначенияСлужебныйКлиент.КонтекстПодключенияКомпоненты 
//
Процедура УстановитьКомпонентуПослеПроверкиДоступности(Результат, Контекст) Экспорт
	
	Если Результат.Доступна Тогда 
		ОбщегоНазначенияСлужебныйКлиент.УстановитьКомпоненту(Контекст);
	Иначе
		ТекстОшибки = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
			           |из хранилища внешних компонент
			           |по причине:
			           |%2'"),
			Контекст.Идентификатор,
			Результат.ОписаниеОшибки);
			
		ОбщегоНазначенияСлужебныйКлиент.УстановитьКомпонентуОповеститьОбОшибке(ТекстОшибки, Контекст);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ЗагрузитьКомпонентуИзФайла

// Возвращаемое значение:
//  Структура:
//   * Оповещение - ОписаниеОповещения
//   * Идентификатор - Строка
//   * Версия - Строка
//   * ПараметрыПоискаДополнительнойИнформации - Соответствие
//
Функция КонтекстЗагрузкиКомпонентыИзФайла() Экспорт
	
	Контекст = Новый Структура;
	Контекст.Вставить("Оповещение", Неопределено);
	Контекст.Вставить("Идентификатор", "");
	Контекст.Вставить("Версия", "");
	Контекст.Вставить("ПараметрыПоискаДополнительнойИнформации", Новый Соответствие);
	Возврат Контекст;
	
КонецФункции
	
// Для вызова из ВнешниеКомпонентыКлиент.ЗагрузитьКомпонентуИзФайла.
// 
// Параметры:
//  Контекст - см. КонтекстЗагрузкиКомпонентыИзФайла.
//
Процедура ЗагрузитьКомпонентуИзФайла(Контекст) Экспорт 
	
	Информация = ВнешниеКомпонентыСлужебныйВызовСервера.ИнформацияОСохраненнойКомпоненте(Контекст.Идентификатор, Контекст.Версия);
	
	Если Информация.ДоступнаЗагрузкаИзФайла Тогда
		
		ПараметрыПоискаДополнительнойИнформации = Контекст.ПараметрыПоискаДополнительнойИнформации;
		
		ПараметрыФормы = Новый Структура;
		ПараметрыФормы.Вставить("ПоказатьДиалогЗагрузкиИзФайлаПриОткрытии", Истина);
		ПараметрыФормы.Вставить("ВернутьРезультатЗагрузкиИзФайла", Истина);
		ПараметрыФормы.Вставить("ПараметрыПоискаДополнительнойИнформации", ПараметрыПоискаДополнительнойИнформации);
		
		Если Информация.Состояние = "НайденаВХранилище"
			Или Информация.Состояние = "ОтключенаАдминистратором" Тогда
			
			ПараметрыФормы.Вставить("ПоказатьДиалогЗагрузкиИзФайлаПриОткрытии", Ложь);
			ПараметрыФормы.Вставить("Ключ", Информация.Ссылка);
		КонецЕсли;
		
		Оповещение = Новый ОписаниеОповещения("ЗагрузитьКомпонентуИзФайлаПослеЗагрузки", ЭтотОбъект, Контекст);
		ОткрытьФорму("Справочник.ВнешниеКомпоненты.ФормаОбъекта", ПараметрыФормы,,,,, Оповещение);
		
	Иначе 
		
		Оповещение = Новый ОписаниеОповещения("ЗагрузитьКомпонентуИзФайлаПослеПредупрежденияДоступности", ЭтотОбъект, Контекст);
		ПоказатьПредупреждение(Оповещение, 
			НСтр("ru = 'Загрузка внешней компоненты прервана
			           |по причине:
			           |Требуются права администратора'"));
		
	КонецЕсли;
	
КонецПроцедуры

// Продолжение процедуры ЗагрузитьКомпонентуИзФайла.
Процедура ЗагрузитьКомпонентуИзФайлаПослеПредупрежденияДоступности(Контекст) Экспорт
	
	Результат = РезультатЗагрузкиКомпоненты();
	Результат.Загружена = Ложь;
	ВыполнитьОбработкуОповещения(Контекст.Оповещение, Результат);
	
КонецПроцедуры

// Продолжение процедуры ЗагрузитьКомпонентуИзФайла.
Процедура ЗагрузитьКомпонентуИзФайлаПослеЗагрузки(Результат, Контекст) Экспорт
	
	// Результат: 
	// - Структура - Загружено.
	// - Неопределено - Закрыто окно. 
	
	ПользовательЗакрылОкно = (Результат = Неопределено);
	
	Оповещение = Контекст.Оповещение;
	
	Если ПользовательЗакрылОкно Тогда 
		Результат = РезультатЗагрузкиКомпоненты();
		Результат.Загружена = Ложь;
	КонецЕсли;
	
	ВыполнитьОбработкуОповещения(Оповещение, Результат);
	
КонецПроцедуры

// Продолжение процедуры ЗагрузитьКомпонентуИзФайла.
Функция РезультатЗагрузкиКомпоненты() Экспорт
	
	Результат = Новый Структура;
	Результат.Вставить("Загружена", Ложь);
	Результат.Вставить("Идентификатор", "");
	Результат.Вставить("Версия", "");
	Результат.Вставить("Наименование", "");
	Результат.Вставить("ДополнительнаяИнформация", Новый Соответствие);
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти

#Область ПоискКомпонентыНаПортале

// Параметры:
//  Оповещение - ОписаниеОповещения
//  Контекст - Структура:
//      * ТекстПояснения - Строка
//      * Идентификатор - Строка
//      * Версия        - Строка
//                      - Неопределено
//
Процедура ПоискКомпонентыНаПортале(Оповещение, Контекст)
	
	ПараметрыФормы = Новый Структура;
	ПараметрыФормы.Вставить("ТекстПояснения", Контекст.ТекстПояснения);
	ПараметрыФормы.Вставить("Идентификатор", Контекст.Идентификатор);
	ПараметрыФормы.Вставить("Версия", Контекст.Версия);
	
	ОповещениеФормы = Новый ОписаниеОповещения("ПоискКомпонентыНаПорталеПриФормированииРезультата", ЭтотОбъект, Оповещение);
	
	ОткрытьФорму("Справочник.ВнешниеКомпоненты.Форма.ПоискКомпонентыНаПортале1СИТС", 
		ПараметрыФормы,,,,, ОповещениеФормы)
	
КонецПроцедуры

Процедура ПоискКомпонентыНаПорталеПриФормированииРезультата(Результат, Оповещение) Экспорт
	
	Загружена = (Результат = Истина); // При закрытии формы будет Неопределено.
	ВыполнитьОбработкуОповещения(Оповещение, Загружена);
	
КонецПроцедуры

#КонецОбласти

#Область ОбновитьКомпонентыСПортала

// Параметры:
//  Оповещение - ОписаниеОповещения
//  ОбновляемыеКомпоненты - Массив из СправочникСсылка.ВнешниеКомпоненты
//
Процедура ОбновитьКомпонентыСПортала(Оповещение, ОбновляемыеКомпоненты) Экспорт
	
	ПараметрыФормы = Новый Структура;
	ПараметрыФормы.Вставить("ОбновляемыеКомпоненты", ОбновляемыеКомпоненты);
	ОповещениеФормы = Новый ОписаниеОповещения("ОбновитьКомпонентыСПорталаПриФормированииРезультата", ЭтотОбъект, Оповещение);
	ОткрытьФорму("Справочник.ВнешниеКомпоненты.Форма.ОбновлениеКомпонентСПортала1СИТС", 
		ПараметрыФормы,,,,, ОповещениеФормы);
	
КонецПроцедуры

Процедура ОбновитьКомпонентыСПорталаПриФормированииРезультата(Результат, Оповещение) Экспорт
	
	ВыполнитьОбработкуОповещения(Оповещение, Неопределено);
	
КонецПроцедуры

#КонецОбласти

#Область СохранитьКомпонентуВФайл

// Параметры:
//  ВнешняяКомпонентаСсылка - СправочникСсылка.ВнешниеКомпоненты
//
Процедура СохранитьКомпонентуВФайл(ВнешняяКомпонентаСсылка) Экспорт 
	
	Местоположение = ПолучитьНавигационнуюСсылку(ВнешняяКомпонентаСсылка, "ХранилищеКомпоненты");
	ИмяФайла = ВнешниеКомпонентыСлужебныйВызовСервера.ИмяФайлаКомпоненты(ВнешняяКомпонентаСсылка);
	
	ПараметрыСохранения = ФайловаяСистемаКлиент.ПараметрыСохраненияФайла();
	ПараметрыСохранения.Диалог.Заголовок = НСтр("ru = 'Выберите файл для сохранения внешней компоненты'");
	ПараметрыСохранения.Диалог.Фильтр    = НСтр("ru = 'Файлы внешних компонент (*.zip)|*.zip|Все файлы (*.*)|*.*'");
	
	Контекст = Новый Структура;
	Контекст.Вставить("Ссылка", ВнешняяКомпонентаСсылка);
	
	Оповещение = Новый ОписаниеОповещения("СохранитьКомпонентуВФайлПослеПолученияФайлов", ЭтотОбъект, Контекст);
	ФайловаяСистемаКлиент.СохранитьФайл(Оповещение, Местоположение, ИмяФайла, ПараметрыСохранения);
	
КонецПроцедуры

// Продолжение процедуры СохранитьКомпонентуВФайл.
Процедура СохранитьКомпонентуВФайлПослеПолученияФайлов(ПолученныеФайлы, Контекст) Экспорт
	
	Если ПолученныеФайлы <> Неопределено 
		И ПолученныеФайлы.Количество() > 0 Тогда
		
		ПоказатьОповещениеПользователя(НСтр("ru = 'Сохранение в файл'"),,
			НСтр("ru = 'Внешняя компонента успешно сохранена в файл.'"), БиблиотекаКартинок.Успешно32);
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#КонецОбласти
