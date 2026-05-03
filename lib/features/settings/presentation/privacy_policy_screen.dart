import 'dart:ui';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: AppBar(
              backgroundColor: isLight
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.85),
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
            // Герой-секция с логотипом
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.95)
                    : const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/duality_logo.png', // замените на правильный путь к логотипу
                    height: 92,
                    width: 92,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Duality Project',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                  const Text(
                    'ALL RIGHTS RESERVED',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 3.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Дата вступления в силу: 1 мая 2026 г.',
                    style: TextStyle(
                      fontSize: 15,
                      color: isLight ? Colors.grey[600] : Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Индикатор open source
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.grey[200] : Colors.grey[800],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      '🔓 Open Source Project',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Блок согласия
                  _buildConsentSection(isLight),
                  const SizedBox(height: 16),
                  // Блок предупреждения о логах
                  _buildLogsWarningSection(isLight),
                  const SizedBox(height: 24),
                  _buildFullPolicyContent(isLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Блок явного согласия
  Widget _buildConsentSection(bool isLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isLight ? Colors.amber[50] : Colors.amber[900])?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade700, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.gavel, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'Ваше согласие обязательно',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Установка и использование мобильного приложения «Rizz» означают ваше полное и безоговорочное согласие с настоящей Политикой конфиденциальности. Если вы не согласны — не устанавливайте приложение.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'При первом запуске вы также сможете подтвердить согласие на экране регистрации.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Блок предупреждения о логах (доступны в открытом виде)
  Widget _buildLogsWarningSection(bool isLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isLight ? Colors.red[50] : Colors.red[900])?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text('Важно: технические логи', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rizz собирает технические логи (версия приложения, модель устройства, ошибки,) для отладки и улучшения стабильности.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Полный текст политики
  Widget _buildFullPolicyContent(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ «RIZZ»', 
          'Настоящая Политика определяет порядок обработки и защиты персональной информации пользователей, которую команда Duality Project (далее — «Администрация») получает во время использования приложения «Rizz».', 
          isLight),
        
        _buildSection('1. Общие положения',
          '1.1. Использование Приложения означает безоговорочное согласие Пользователя с настоящей Политикой.\n'
          '1.2. В случае несогласия Пользователь обязан незамедлительно прекратить использование Приложения и удалить учётную запись.\n'
          '1.3. Обработка данных осуществляется с целью исполнения лицензионного соглашения между Пользователем и Администрацией.\n'
          '1.4. Вы вправе запустить собственную копию Rizz на своей инфраструктуре — в этом случае данная Политика не применяется, и вы сами отвечаете за данные.',
          isLight),
        
        _buildSection('2. Состав собираемых данных',
          '• Регистрационные данные: email, UID, никнейм, отображаемое имя, номер телефона (опционально), аватар и биография.\n'
          '• Пользовательский контент: сообщения, фото, видео и аудио. Контент хранится в Google Firebase с использованием шифрования TLS/SSL.\n'
          '• Техническая информация: ID устройства, модель, версия ОС, Push-токены, системные логи (ошибки, стеки вызовов).\n'
          '• Контакты: доступ к списку контактов осуществляется только на основании явного разрешения пользователя, используется для поиска друзей внутри Приложения.\n'
          '• Данные об обновлениях: версия, размер пакета, контрольная сумма (хранятся на update.rizzdp.ru).',
          isLight),
        
        _buildSection('3. Цели обработки информации',
          '• Обеспечение функциональности мессенджера и синхронизации между устройствами.\n'
          '• Отправка транзакционных сообщений и Push-уведомлений (новые сообщения).\n'
          '• Предотвращение мошенничества, спама и взломов (анализ аномального поведения).\n'
          '• Анализ технических логов для исправления ошибок и улучшения производительности.\n'
          '• Соблюдение требований законодательства (например, по запросу правоохранительных органов).',
          isLight),
        
        _buildSection('4. Правовые основания и хранение данных',
          '4.1. Обработка базируется на исполнении договора (лицензионного соглашения) и законном интересе Администрации в безопасности сервиса.\n'
          '4.2. Место хранения данных: серверы Google Cloud Platform (Firebase) в регионе eur3 (Европа). Осуществляется трансграничная передача персональных данных.\n'
          '4.3. Срок хранения: весь период активности учётной записи. После удаления аккаунта данные безвозвратно удаляются в течение 30 дней.\n'
          '4.4. Логи хранятся на logs.rizzdp.ru и могут быть удалены в любой момент.',
          isLight),
        
        _buildSection('5. Передача данных третьим лицам',
          '5.1. Администрация не продаёт персональные данные и не передаёт их рекламным сетям.\n'
          '5.2. Передача возможна только:\n'
          '   • Google Ireland Limited (Firebase) для обеспечения работы инфраструктуры.\n'
          '   • Правоохранительным органам на основании официального запроса в порядке, установленном законодательством РФ или страны проживания пользователя.\n',
          isLight),
        
        _buildSection('6. Права пользователя',
          'В соответствии с ФЗ-152 «О персональных данных» вы имеете право на:\n'
          '• Доступ и изменение данных профиля (через настройки приложения).\n'
          '• «Право на забвение» — полное удаление аккаунта.\n'
          '• Отзыв разрешений (контакты, камера, микрофон) в настройках операционной системы.\n'
          '• Запрос информации о сборе и обработке данных (пишите на dualityproject01@gmail.com).',
          isLight),
        
        _buildSection('7. Защита несовершеннолетних',
          '7.1. Приложение не предназначено для лиц младше 13 лет.\n'
          '7.2. Если мы обнаружим данные ребёнка без подтверждённого согласия родителей, такая информация будет немедленно удалена. Родители/опекуны могут обратиться к нам для удаления учётной записи.',
          isLight),
        
        _buildSection('8. Ограничение ответственности',
          '8.1. Мы принимаем все разумные меры для защиты данных (шифрование, контроль доступа), однако ни один метод передачи данных в интернете не является на 100% безопасным.\n'
          '8.2. Пользователь несёт ответственность за сохранность своих учётных данных (логин/пароль).\n'
          '8.3. Администрация не несёт ответственности за содержимое сообщений, переданных пользователями.',
          isLight),
        
        _buildSection('9. Изменения политики',
          '9.1. Администрация может вносить изменения в одностороннем порядке при изменении законодательства или функционала сервиса.\n'
          '9.2. Уведомление об изменениях происходит через обновление даты в документе. При существенных изменениях мы отправим внутриприложенное уведомление.\n'
          '9.3. Продолжение использования приложения после изменений означает ваше согласие с новой редакцией.',
          isLight),
        
        _buildSection('10. Контактная информация',
          'По всем вопросам обработки персональных данных вы можете обратиться к Администрации:\n'
          '📧 Email: dualityproject01@gmail.com\n'
          '📬 Telegram: @DualityProject\n'
          'Команда разработки Duality Project.',
          isLight),
        
        const SizedBox(height: 40),
        Center(
          child: Text(
            '© 2025–2026 Duality Project / Rizz',
            style: TextStyle(fontSize: 12, color: isLight ? Colors.grey[600] : Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSection(String title, String content, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
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