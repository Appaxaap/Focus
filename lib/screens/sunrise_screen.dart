import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/task_provider.dart';
import '../models/task_models.dart';
import '../models/quadrant_enum.dart';
import 'home_screen.dart';

class SunriseScreen extends ConsumerStatefulWidget {
  const SunriseScreen({super.key});

  @override
  ConsumerState<SunriseScreen> createState() => _SunriseScreenState();
}

class _SunriseScreenState extends ConsumerState<SunriseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Delay the button appearance to encourage reading the message
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isButtonVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper function to build the contextual message
  String _buildContextMessage(List<Task> tasks) {
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
    final overdueTasks = incompleteTasks
        .where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .length;
    final doFirstTasks = incompleteTasks
        .where((t) => t.quadrant == Quadrant.urgentImportant)
        .length;

    if (overdueTasks > 0) {
      return "You have $overdueTasks overdue tasks. Let's get you back on track.";
    }
    if (doFirstTasks > 0) {
      return "There are $doFirstTasks high-priority tasks waiting. Time to focus on what matters.";
    }
    if (incompleteTasks.isEmpty) {
      return "You're starting with a clean slate. A perfect day to schedule what's important.";
    }
    return "Here's a look at your focus for today.";
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = _buildContextMessage(tasks);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2c3e50), // Deep blue
              const Color(0xFFfd746c), // Soft red/orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      size: 60,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Good morning.",
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  AnimatedOpacity(
                    opacity: _isButtonVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      child: const Text("Begin Your Day"),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
