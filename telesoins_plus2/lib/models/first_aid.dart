class FirstAidModule {
  final String id;
  final String title;
  final String description;
  final String category;
  final int difficultyLevel;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FirstAidContent>? contents;
  final List<Quiz>? quizzes;
  
  FirstAidModule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficultyLevel,
    required this.order,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.contents,
    this.quizzes,
  });
  
  String get difficultyLabel {
    switch (difficultyLevel) {
      case 1: return 'Débutant';
      case 2: return 'Intermédiaire';
      case 3: return 'Avancé';
      default: return 'Inconnu';
    }
  }
  
  factory FirstAidModule.fromJson(Map<String, dynamic> json) {
    return FirstAidModule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficultyLevel: json['difficulty_level'],
      order: json['order'] ?? 0,
      isPublished: json['is_published'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      contents: json['contents'] != null 
        ? (json['contents'] as List)
            .map((c) => FirstAidContent.fromJson(c))
            .toList() 
        : null,
      quizzes: json['quizzes'] != null 
        ? (json['quizzes'] as List)
            .map((q) => Quiz.fromJson(q))
            .toList() 
        : null,
    );
  }
}

class FirstAidContent {
  final String id;
  final String moduleId;
  final String title;
  final String contentType;
  final String? content;
  final String? fileUrl;
  final int fileSize;
  final int order;
  
  FirstAidContent({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.contentType,
    this.content,
    this.fileUrl,
    required this.fileSize,
    required this.order,
  });
  
  String get contentTypeLabel {
    switch (contentType) {
      case 'video': return 'Vidéo';
      case 'image': return 'Image';
      case 'audio': return 'Audio';
      case 'text': return 'Texte';
      case 'checklist': return 'Checklist';
      default: return 'Inconnu';
    }
  }
  
  bool get isFile => contentType == 'video' || contentType == 'image' || contentType == 'audio';
  bool get isText => contentType == 'text' || contentType == 'checklist';
  
  factory FirstAidContent.fromJson(Map<String, dynamic> json) {
    return FirstAidContent(
      id: json['id'],
      moduleId: json['module'],
      title: json['title'],
      contentType: json['content_type'],
      content: json['content'],
      fileUrl: json['file'],
      fileSize: json['file_size'] ?? 0,
      order: json['order'] ?? 0,
    );
  }
}

class Quiz {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final int passingScore;
  final List<QuizQuestion>? questions;
  
  Quiz({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    required this.passingScore,
    this.questions,
  });
  
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      moduleId: json['module'],
      title: json['title'],
      description: json['description'],
      passingScore: json['passing_score'] ?? 70,
      questions: json['questions'] != null 
        ? (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q))
            .toList() 
        : null,
    );
  }
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final int order;
  final List<QuizOption>? options;
  
  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.order,
    this.options,
  });
  
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz'],
      questionText: json['question_text'],
      order: json['order'] ?? 0,
      options: json['options'] != null 
        ? (json['options'] as List)
            .map((o) => QuizOption.fromJson(o))
            .toList() 
        : null,
    );
  }
}

class QuizOption {
  final String id;
  final String questionId;
  final String optionText;
  final bool isCorrect;
  
  QuizOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
  });
  
  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      questionId: json['question'],
      optionText: json['option_text'],
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final String quizTitle;
  final int score;
  final DateTime completedAt;
  final bool passed;
  
  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.completedAt,
    required this.passed,
  });
  
  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'],
      userId: json['user'],
      quizId: json['quiz'],
      quizTitle: json['quiz_title'] ?? '',
      score: json['score'],
      completedAt: DateTime.parse(json['completed_at']),
      passed: json['passed'] ?? false,
    );
  }
}

class ModuleProgress {
  final String moduleId;
  final String moduleTitle;
  final String moduleCategory;
  final String moduleDifficulty;
  final bool completed;
  final int score;
  final bool passed;
  final DateTime? date;
  
  ModuleProgress({
    required this.moduleId,
    required this.moduleTitle,
    required this.moduleCategory,
    required this.moduleDifficulty,
    required this.completed,
    required this.score,
    required this.passed,
    this.date,
  });
  
  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['module_id'],
      moduleTitle: json['module_title'],
      moduleCategory: json['module_category'],
      moduleDifficulty: json['module_difficulty'],
      completed: json['completed'] ?? false,
      score: json['score'] ?? 0,
      passed: json['passed'] ?? false,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }
}