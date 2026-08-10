import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/ai_chat_provider.dart';

class FitGineAIFloatingButton extends ConsumerStatefulWidget {
  const FitGineAIFloatingButton({super.key});

  @override
  ConsumerState<FitGineAIFloatingButton> createState() => _FitGineAIFloatingButtonState();
}

class _FitGineAIFloatingButtonState extends ConsumerState<FitGineAIFloatingButton>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  Offset _offset = const Offset(20, 80);
  double? _customWidth;
  double? _customHeight;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _pulseController;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _quickPrompts = [
    "How do I improve my squat form?",
    "Suggest a beginner chest workout",
    "How much protein do I need?",
    "Tips for workout recovery",
  ];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
        ref.read(aiChatProvider.notifier).markAsRead();
        _scrollToBottom();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _updateOffset(Offset delta, Size screenSize, [double? currentWidth, double? currentHeight]) {
    final w = _isExpanded ? (currentWidth ?? 380.0) : 56.0;
    final h = _isExpanded ? (currentHeight ?? 560.0) : 56.0;
    final newX = (_offset.dx - delta.dx).clamp(12.0, (screenSize.width - w - 12.0).clamp(12.0, screenSize.width));
    final newY = (_offset.dy - delta.dy).clamp(12.0, (screenSize.height - h - 12.0).clamp(12.0, screenSize.height));
    setState(() => _offset = Offset(newX, newY));
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

  void _handleSend([String? textToSend]) {
    final text = textToSend ?? _textController.text;
    if (text.trim().isEmpty) return;

    ref.read(aiChatProvider.notifier).sendMessage(text, isPanelOpen: _isExpanded);
    _textController.clear();
    _scrollToBottom();
  }

  void _onPromptChipTap(String prompt) {
    _textController.text = prompt;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final chatState = ref.watch(aiChatProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = screenSize.width >= 600;

    // Listen for new messages to auto-scroll
    ref.listen<AiChatState>(aiChatProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0) || next.isLoading) {
        if (_isExpanded) {
          _scrollToBottom();
        }
      }
    });

    // Panel dimensions (resizable)
    final minWidth = 300.0;
    final maxWidth = (screenSize.width - 32.0).clamp(minWidth, 1200.0);
    final minHeight = 350.0;
    final maxHeight = (screenSize.height - 32.0).clamp(minHeight, 1200.0);

    final defaultWidth = isDesktop ? 380.0 : (screenSize.width * 0.88).clamp(300.0, 440.0);
    final defaultHeight = isDesktop ? 560.0 : (screenSize.height * 0.72).clamp(420.0, 650.0);

    final panelWidth = (_customWidth ?? defaultWidth).clamp(minWidth, maxWidth);
    final panelHeight = (_customHeight ?? defaultHeight).clamp(minHeight, maxHeight);

    return Positioned(
      right: _offset.dx,
      bottom: _offset.dy,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Expanded Floating Chat Panel
          ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Container(
                width: panelWidth,
                height: panelHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Panel Header
                          _buildHeader(context, screenSize, panelWidth, panelHeight),

                          // Messages List
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < chatState.messages.length) {
                                  final message = chatState.messages[index];
                                  return _buildMessageBubble(context, message, isDarkMode);
                                } else {
                                  return _buildLoadingBubble(context, isDarkMode);
                                }
                              },
                            ),
                          ),

                          // Quick Prompts Chips
                          _buildQuickPrompts(context),

                          // Input Bar
                          _buildInputBar(context, chatState),
                        ],
                      ),

                      // Top-Left Corner Visual Grip Handle
                      Positioned(
                        top: 6,
                        left: 6,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.north_west_rounded,
                              size: 11,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),

                      // 1. Top Edge Handle (Vertical Resize)
                      Positioned(
                        top: 0,
                        left: 20,
                        right: 20,
                        height: 12,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeUpDown,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (details) {
                              setState(() {
                                _customHeight = (panelHeight - details.delta.dy).clamp(minHeight, maxHeight);
                              });
                            },
                          ),
                        ),
                      ),

                      // 2. Left Edge Handle (Horizontal Resize)
                      Positioned(
                        top: 20,
                        left: 0,
                        bottom: 20,
                        width: 12,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (details) {
                              setState(() {
                                _customWidth = (panelWidth - details.delta.dx).clamp(minWidth, maxWidth);
                              });
                            },
                          ),
                        ),
                      ),

                      // 3. Top-Left Corner Handle (2D Resize)
                      Positioned(
                        top: 0,
                        left: 0,
                        width: 24,
                        height: 24,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeUpLeft,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (details) {
                              setState(() {
                                _customWidth = (panelWidth - details.delta.dx).clamp(minWidth, maxWidth);
                                _customHeight = (panelHeight - details.delta.dy).clamp(minHeight, maxHeight);
                              });
                            },
                          ),
                        ),
                      ),

                      // 4. Top-Right Corner Handle
                      Positioned(
                        top: 0,
                        right: 0,
                        width: 24,
                        height: 24,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeUpRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (details) {
                              setState(() {
                                _customWidth = (panelWidth + details.delta.dx).clamp(minWidth, maxWidth);
                                _customHeight = (panelHeight - details.delta.dy).clamp(minHeight, maxHeight);
                              });
                            },
                          ),
                        ),
                      ),

                      // 5. Bottom-Left Corner Handle
                      Positioned(
                        bottom: 0,
                        left: 0,
                        width: 24,
                        height: 24,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeDownLeft,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanUpdate: (details) {
                              setState(() {
                                _customWidth = (panelWidth - details.delta.dx).clamp(minWidth, maxWidth);
                                _customHeight = (panelHeight + details.delta.dy).clamp(minHeight, maxHeight);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Circular Trigger Button (visible when collapsed)
          if (!_isExpanded)
            GestureDetector(
              onPanUpdate: (details) => _updateOffset(details.delta, screenSize),
              onTap: _toggleExpand,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = chatState.hasUnread ? _pulseController.value : 0.0;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (chatState.hasUnread)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4 + (pulseValue * 0.4)),
                            blurRadius: 12 + (pulseValue * 8),
                            spreadRadius: 2 + (pulseValue * 4),
                          ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/icon/app_icon_avatar.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size screenSize, double panelWidth, double panelHeight) {
    return GestureDetector(
      onPanUpdate: (details) => _updateOffset(details.delta, screenSize, panelWidth, panelHeight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLightOf(context),
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderOf(context),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28 * 0.22),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(28 * 0.12),
                child: Image.asset(
                  'assets/icon/app_icon_avatar.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FitGenie AI',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(context),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Clear Chat',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
            ),
            IconButton(
              tooltip: 'Minimize',
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
              onPressed: _toggleExpand,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, bool isDarkMode) {
    final isUser = message.sender == ChatSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24 * 0.22),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(24 * 0.12),
                child: Image.asset(
                  'assets/icon/app_icon_avatar.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: !isUser
                    ? Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimaryOf(context),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textMutedOf(context),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 14),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  Widget _buildLoadingBubble(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24 * 0.22),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(24 * 0.12),
              child: Image.asset(
                'assets/icon/app_icon_avatar.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 150.ms),
    );
  }

  Widget _buildQuickPrompts(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
              label: Text(
                prompt,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              backgroundColor: AppColors.surfaceLightOf(context),
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () => _onPromptChipTap(prompt),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AiChatState chatState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightOf(context),
        border: Border(
          top: BorderSide(color: AppColors.borderOf(context), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: 'Ask FitGenie AI...',
                hintStyle: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surfaceOf(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onSubmitted: (value) => _handleSend(value),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: chatState.isLoading ? null : () => _handleSend(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
