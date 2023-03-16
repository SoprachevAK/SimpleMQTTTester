# Simple MQTT Tester

Приложение для тестирование MQTT брокеров для IOS.

## Возможности

1. Подключение к брокеру по логину и паролю с указанием хоста и порта брокера, возможно отключить проверку сертификата.
2. Отправка данных с акселерометра в указанный топик с указанной частотой
3. Подписка на указанный топик с получением сообщений от него

## Поддерживаемые версии

iOS/iPadOS 16.0 и выше

## Установка

### Через публичную ссылку TestFlight

Открыть ссылку с iOS устройства, следовать инструкциям [https://testflight.apple.com/join/iqbSAIiv](https://testflight.apple.com/join/iqbSAIiv)

### Через сборку исходников

Необходим менеджер зависимостей CacoaPods

```bash
git clone https://github.com/SoprachevAK/SimpleMQTTTester.git
pod install
```

После чего открыть проект с помощью Xcode и скомпилировать его стандартным способом.

## Особенности

Основная бизнес логика взаимодействия с MQTT находится в файле [MqttTester/Core/MqttViewModel.swift](./MqttTester/Core/MqttViewModel.swift)

Интерфейс написан на SwiftUI
