import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/ai_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final chatLangProvider = StateProvider<bool>((ref) => true);

final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

// ---------------------------------------------------------------------------
// ChatScreen
// ---------------------------------------------------------------------------

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final inBengali = ref.read(chatLangProvider);
    final history = ref.read(chatMessagesProvider);

    final userMsg = ChatMessage(
      role: MessageRole.user,
      text: text,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).state = [...history, userMsg];
    _inputController.clear();
    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      final response = await AiService().sendMessage(
        userMessage: text,
        history: history,
        inBengali: inBengali,
      );

      final aiMsg = ChatMessage(
        role: MessageRole.model,
        text: response,
        timestamp: DateTime.now(),
      );

      ref.read(chatMessagesProvider.notifier).state = [
        ...ref.read(chatMessagesProvider),
        aiMsg,
      ];
    } catch (e) {
      final errorText = inBengali
          ? 'কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন।'
          : 'Something went wrong. Please try again.';

      final errorMsg = ChatMessage(
        role: MessageRole.model,
        text: errorText,
        timestamp: DateTime.now(),
      );

      ref.read(chatMessagesProvider.notifier).state = [
        ...ref.read(chatMessagesProvider),
        errorMsg,
      ];
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final inBengali = ref.watch(chatLangProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'কৃষক AI',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  inBengali ? 'কৃষি সহায়ক' : 'Agri Assistant',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // BN/EN toggle
          GestureDetector(
            onTap: () => ref.read(chatLangProvider.notifier).state = !inBengali,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                inBengali ? 'EN' : 'বাং',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Clear chat
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 22),
            tooltip: inBengali ? 'চ্যাট মুছুন' : 'Clear chat',
            onPressed: messages.isEmpty
                ? null
                : () {
                    ref.read(chatMessagesProvider.notifier).state = [];
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(inBengali)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _TypingIndicator();
                      }
                      return _MessageBubble(message: messages[index]);
                    },
                  ),
          ),
          _buildInputBar(inBengali),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool inBengali) {
    final suggestions = inBengali
        ? [
            'ধানের ব্লাস্ট রোগের প্রতিকার কী?',
            'টমেটোতে পোকা দমনের উপায়?',
            'সেচের সঠিক সময় কখন?',
            'মাটি পরীক্ষার গুরুত্ব কী?',
          ]
        : [
            'How to treat rice blast disease?',
            'How to control pests on tomato?',
            'When is the best time to irrigate?',
            'Why is soil testing important?',
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.eco_outlined,
                color: AppTheme.primaryGreen, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            inBengali ? 'কৃষি বিশেষজ্ঞ সহায়ক' : 'Agricultural Expert',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            inBengali
                ? 'ফসল, রোগ, সার বা চাষ পদ্ধতি নিয়ে যেকোনো প্রশ্ন করুন'
                : 'Ask anything about crops, diseases, fertilizers or farming',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ...suggestions.map(
            (s) => GestureDetector(
              onTap: () {
                _inputController.text = s.substring(3);
                _send();
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool inBengali) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 24,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: inBengali
                    ? 'আপনার কৃষি প্রশ্ন লিখুন...'
                    : 'Ask your farming question...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    _isLoading ? Colors.grey.shade300 : AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading ? Colors.grey : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.smart_toy_outlined,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    const Text('কৃষক AI',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final value = ((_controller.value - delay) % 1.0);
                final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen
                        .withValues(alpha: opacity.clamp(0.3, 1.0)),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
