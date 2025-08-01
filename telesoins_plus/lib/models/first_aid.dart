enum ModuleLevel {
  beginner,
  intermediate,
  advanced
}

class FirstAidModule {
  final int id;
  final String title;
  final String description;
  final String iconUrl;
  final ModuleLevel level;
  final List<FirstAidContent> contents;
  final FirstAidQuiz? quiz;
  final bool isDownloadable;
  final int? downloadSizeKb;

  FirstAidModule({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.level,
    required this.contents,
    this.quiz,
    this.isDownloadable = false,
    this.downloadSizeKb,
  });

  factory FirstAidModule.fromJson(Map<String, dynamic> json) {
    List<FirstAidContent> contents = [];
    if (json['contents'] != null) {
      contents = List<FirstAidContent>.from(
        json['contents'].map((contentJson) => FirstAidContent.fromJson(contentJson))
      );
    }

    return FirstAidModule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      iconUrl: json['icon_url'],
      level: _levelFromString(json['level']),
      contents: contents,
      quiz: json['quiz'] != null ? FirstAidQuiz.fromJson(json['quiz']) : null,
      isDownloadable: json['is_downloadable'] ?? false,
      downloadSizeKb: json['download_size_kb'],
    );
  }

  static ModuleLevel _levelFromString(String level) {
    switch (level) {
      case 'beginner':
        return ModuleLevel.beginner;
      case 'intermediate':
        return ModuleLevel.intermediate;
      case 'advanced':
        return ModuleLevel.advanced;
      default:
        return ModuleLevel.beginner;
    }
  }

  String get levelText {
    switch (level) {
      case ModuleLevel.beginner:
        return 'Débutant';
      case ModuleLevel.intermediate:
        return 'Intermédiaire';
      case ModuleLevel.advanced:
        return 'Avancé';
    }
  }
}

enum ContentType {
  text,
  image,
  video,
  audio,
  checklist
}

class FirstAidContent {
  final int id;
  final String title;
  final ContentType type;
  final String content;
  final int order;
  final String? mediaUrl;
  final bool isRequired;

  FirstAidContent({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.order,
    this.mediaUrl,
    this.isRequired = true,
  });

  factory FirstAidContent.fromJson(Map<String, dynamic> json) {
    return FirstAidContent(
      id: json['id'],
      title: json['title'],
      type: _typeFromString(json['type']),
      content: json['content'],
      order: json['order'],
      mediaUrl: json['media_url'],
      isRequired: json['is_required'] ?? true,
    );
  }

  static ContentType _typeFromString(String type) {
    switch (type) {
      case 'text':
        return ContentType.text;
      case 'image':
        return ContentType.image;
      case 'video':
        return ContentType.video;
      case 'audio':
        return ContentType.audio;
      case 'checklist':
        return ContentType.checklist;
      default:
        return ContentType.text;
    }
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctOption;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctOption: json['correct_option'],
      explanation: json['explanation'],
    );
  }
}

class FirstAidQuiz {
  final int id;
  final String title;
  final String description;
  final List<QuizQuestion> questions;
  final int passingScore;

  FirstAidQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.passingScore = 70,
  });

  factory FirstAidQuiz.fromJson(Map<String, dynamic> json) {
    List<QuizQuestion> questions = [];
    if (json['questions'] != null) {
      questions = List<QuizQuestion>.from(
        json['questions'].map((qJson) => QuizQuestion.fromJson(qJson))
      );
    }

    return FirstAidQuiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions: questions,
      passingScore: json['passing_score'] ?? 70,
    );
  }
}