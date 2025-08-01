import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/first_aid.dart';
import 'package:telesoins_plus/services/storage_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';

class QuizScreen extends StatefulWidget {
  final int moduleId;
  final FirstAidQuiz quiz;

  const QuizScreen({
    Key? key,
    required this.moduleId,
    required this.quiz,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final StorageService _storageService = StorageService();
  int _currentQuestionIndex = 0;
  List<int?> _answers = [];
  bool _isSubmitting = false;
  bool _quizCompleted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnswers();
  }

  void _initializeAnswers() {
    _answers = List.filled(widget.quiz.questions.length, null);
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _answers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  Future<void> _submitQuiz() async {
    // Vérifier si toutes les questions ont une réponse
    if (_answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez répondre à toutes les questions'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Calculer le score
      int correctAnswers = 0;
      for (int i = 0; i < widget.quiz.questions.length; i++) {
        if (_answers[i] == widget.quiz.questions[i].correctOption) {
          correctAnswers++;
        }
      }
      
      _score = (correctAnswers / widget.quiz.questions.length * 100).round();
      final isPassed = _score >= widget.quiz.passingScore;
      
      // Sauvegarder le résultat du quiz localement
      await _storageService.saveFirstAidContent(
        'quiz_${widget.moduleId}_result',
        _score.toString(),
      );
      
      setState(() {
        _quizCompleted = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _initializeAnswers();
      _currentQuestionIndex = 0;
      _quizCompleted = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.quiz.title,
        type: AppBarType.patient,
      ),
      body: _isSubmitting
          ? const LoadingIndicator()
          : _quizCompleted
              ? _buildResultScreen()
              : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final currentAnswer = _answers[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progression
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Question
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Options
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final isSelected = currentAnswer == index;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _selectAnswer(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey.shade200,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D...
                                style: TextStyle(
                                  color: isSelected 
                                      ? Colors.white 
                                      : AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
              if (_currentQuestionIndex < widget.quiz.questions.length - 1)
                ElevatedButton.icon(
                  onPressed: _goToNextQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Suivant'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _submitQuiz,
                  icon: const Icon(Icons.check),
                  label: const Text('Terminer'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final isPassed = _score >= widget.quiz.passingScore;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de réussite ou d'échec
            Icon(
              isPassed ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: isPassed ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(height: 24),
            
            // Titre
            Text(
              isPassed ? 'Félicitations !' : 'Vous pouvez faire mieux',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Score
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              decoration: BoxDecoration(
                color: isPassed 
                    ? AppTheme.successColor.withOpacity(0.1) 
                    : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Votre score: $_score%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Message
            Text(
              isPassed
                  ? 'Vous avez réussi ce quiz ! Vous maîtrisez les bases de ce module.'
                  : 'Vous n\'avez pas atteint le score minimum requis (${widget.quiz.passingScore}%). Révisez le module et réessayez.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            
            // Boutons d'action
           Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: _resetQuiz,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refaire le quiz', overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 8), // Réduit l'espace entre les boutons
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Retour au module', overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}