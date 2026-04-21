import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      // iOS-style стеклянный AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: AppBar(
              backgroundColor: isLight
                  ? Colors.white.withOpacity(0.85)
                  : Colors.black.withOpacity(0.85),
              foregroundColor: isLight ? Colors.black : Colors.white,
              elevation: 0,
              centerTitle: false,
              title: const Text(
                'Политика конфиденциальности',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==================== ГЕРОЙ-СЕКЦИЯ С ЛОГОТИПОМ ====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withOpacity(0.95)
                    : const Color(0xFF1C1C1E).withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(
                    color: isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Логотип (замените путь на ваш реальный ассет)
                  Image.asset(
                    'assets/images/duality_logo.png', // ← ЗАГРУЗИТЕ СЮДА ВАШ ЛОГОТИП
                    height: 92,
                    width: 92,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Duality Project',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'ALL RIGHTS RESERVED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Дата вступления в силу: 26 марта 2026 г.',
                    style: TextStyle(
                      fontSize: 15,
                      color: isLight ? Colors.grey[600] : Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ==================== ОСНОВНОЙ КОНТЕНТ ====================
            
Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSection(
        'ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ «RIZZ»',
        'Дата вступления в силу: 21 апреля 2026 г.\n\n'
        'Настоящая Политика определяет порядок обработки и защиты персональной информации пользователей, которую команда Duality Project (далее — «Администрация») получает во время использования мобильного приложения «Rizz».',
        isLight,
      ),
      _buildSection(
        '1. Общие положения',
        '1.1. Использование Приложения означает безоговорочное согласие Пользователя с настоящей Политикой.\n'
        '1.2. В случае несогласия с условиями Пользователь обязан незамедлительно прекратить использование Приложения.\n'
        '1.3. Обработка данных осуществляется с целью исполнения лицензионного соглашения между Пользователем и Администрацией.',
        isLight,
      ),
      _buildSection(
        '2. Состав собираемых данных',
        'Администрация обрабатывает следующие категории данных:\n\n'
        '• Регистрационные данные: email, UID, никнейм, отображаемое имя, номер телефона (опционально), аватар и биография.\n'
        '• Пользовательский контент: сообщения, фото, видео и аудио. Контент хранится в Google Firebase с использованием HEX-преобразования и шифрования TLS/SSL.\n'
        '• Техническая информация: ID устройства, модель, версия ОС, Push-токены и системные логи.\n'
        '• Контакты: доступ осуществляется только на основании явного разрешения для поиска связей внутри Приложения.',
        isLight,
      ),
      _buildSection(
        '3. Цели обработки информации',
        'Мы используем данные для:\n'
        '3.1. Обеспечения функциональности мессенджера и синхронизации.\n'
        '3.2. Отправки транзакционных сообщений и оперативных Push-уведомлений.\n'
        '3.3. Предотвращения мошенничества, спама и взломов.\n'
        '3.4. Анализа технических логов для исправления ошибок.',
        isLight,
      ),
      _buildSection(
        '4. Правовые основания и хранение',
        '4.1. Обработка базируется на исполнении договора и законном интересе Администрации в безопасности сервиса.\n'
        '4.2. Место хранения: Серверы Google Cloud Platform (инфраструктура Firebase).\n'
        '4.3. Срок хранения: Весь период активности аккаунта до момента получения требования об удалении.',
        isLight,
      ),
      _buildSection(
        '5. Передача данных третьим лицам',
        '5.1. Администрация не продает персональные данные в маркетинговых целях.\n'
        '5.2. Передача возможна только в адрес Google Ireland Limited (Firebase) для работы инфраструктуры или правоохранительным органам по официальному запросу.',
        isLight,
      ),
      _buildSection(
        '6. Права пользователя',
        'В соответствии с международными стандартами (GDPR), вы имеете право на:\n'
        '• Доступ и изменение данных профиля.\n'
        '• «Право на забвение» (полное удаление аккаунта и контента).\n'
        '• Отзыв разрешений (контакты, камера, микрофон) в настройках ОС.',
        isLight,
      ),
      _buildSection(
        '7. Защита несовершеннолетних',
        '7.1. Приложение не предназначено для лиц младше 13 лет.\n'
        '7.2. При обнаружении данных ребенка без согласия опекунов, Администрация немедленно удаляет такую информацию.',
        isLight,
      ),
      _buildSection(
        '8. Ограничение ответственности',
        '8.1. Мы принимаем все разумные меры защиты, однако ни один метод передачи данных в интернете не является на 100% безопасным.\n'
        '8.2. Пользователь несет ответственность за сохранность своих учетных данных.',
        isLight,
      ),
      _buildSection(
        '9. Изменения политики',
        '9.1. Администрация может вносить изменения в одностороннем порядке.\n'
        '9.2. Уведомление об изменениях происходит через обновление даты в документе или системное сообщение в Приложении.',
        isLight,
      ),
      _buildSection(
        '10. Контактная информация',
        'По всем вопросам:\n'
        'Email: dualityproject01@gmail.com\n'
        'Субъект управления: Команда разработки Duality Project.',
        isLight,

                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isLight ? Colors.black87 : Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.55,
              color: isLight ? Colors.black87 : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}