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
                    '1. Введение',
                    'Команда Duality Project с глубоким уважением относится к вашей конфиденциальности. Мы создали Rizz как пространство абсолютной свободы самовыражения — и делаем всё возможное, чтобы это пространство оставалось безопасным и защищённым.\n\n'
                    'Настоящая Политика конфиденциальности — это наш торжественный договор с вами. Используя приложение, вы принимаете его условия.',
                    isLight,
                  ),

                  _buildSection(
                    '2. Собираемая информация',
                    'Мы собираем только то, что действительно необходимо для работы Rizz:\n\n'
                    '• Данные профиля: email, никнейм, отображаемое имя, номер телефона (по желанию), аватар и биография.\n'
                    '• Пользовательский контент: сообщения, фото, видео, файлы и голосовые — всё хранится в зашифрованном HEX-формате в Firebase Firestore.\n'
                    '• Технические данные: модель устройства, ОС, push-токен FCM и анонимизированные логи для стабильности.\n'
                    '• Контакты: только с вашего явного согласия — исключительно для поиска друзей внутри приложения.',
                    isLight,
                  ),

                  _buildSection(
                    '3. Как мы используем вашу информацию',
                    'Всё очень просто и честно:\n'
                    '— Чтобы вы могли общаться, делиться моментами и быть собой.\n'
                    '— Чтобы приложение работало быстро, красиво и стабильно.\n'
                    '— Чтобы мы могли защищать вас от спама и злоупотреблений.\n'
                    '— Чтобы推送-уведомления о новых сообщениях приходили мгновенно.',
                    isLight,
                  ),

                  _buildSection(
                    '4. Хранение и защита данных',
                    'Ваш контент преобразуется в HEX перед сохранением и хранится в Google Cloud Firestore. Мы применяем все современные меры защиты. Тем не менее, абсолютной безопасности в интернете не существует — мы всегда будем максимально честны с вами по этому поводу.',
                    isLight,
                  ),

                  _buildSection(
                    '5. Раскрытие информации',
                    'Мы никогда не продаём ваши данные. Никогда.\n\n'
                    'Передача возможна только:\n'
                    '• Сервисам Firebase (Google), которые обеспечивают работу приложения.\n'
                    '• По законному требованию государственных органов.',
                    isLight,
                  ),

                  _buildSection(
                    '6. Ваши права',
                    'Вы — хозяин своих данных.\n\n'
                    'Вы можете в любой момент:\n'
                    '• Изменить или удалить профиль\n'
                    '• Удалить любое сообщение\n'
                    '• Полностью удалить аккаунт\n'
                    '• Отозвать любые разрешения',
                    isLight,
                  ),

                  _buildSection(
                    '7. Дети и несовершеннолетние',
                    'Rizz предназначен для пользователей старше 13 лет. Мы не собираем данные детей младше этого возраста. Если такое произойдёт — немедленно удалим информацию.',
                    isLight,
                  ),

                  _buildSection(
                    '8. Изменения в политике',
                    'Мы можем обновлять эту Политику. О существенных изменениях вы узнаете первым — через уведомление в приложении.',
                    isLight,
                  ),

                  _buildSection(
                    '9. Контакты',
                    'Duality Project\n'
                    'Электронная почта: dualityproject01@gmail.com\n\n'
                    'Мы всегда на связи.',
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