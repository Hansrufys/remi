import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:remi/core/utils/retry_helper.dart';

class ExtractionResult {
  final String type;
  final String summary;
  final String? personName;
  final String? taskDescription;
  final String? remindAt;
  final String? insightDetail;
  final String? spinoReaction;
  final String? spinoNotification;
  final String? globalAction;

  const ExtractionResult({
    required this.type,
    required this.summary,
    this.personName,
    this.taskDescription,
    this.remindAt,
    this.insightDetail,
    this.spinoReaction,
    this.spinoNotification,
    this.globalAction,
  });

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    getProp(String key) => json[key] ?? json[key.toLowerCase()] ?? json[key.replaceAll(RegExp(r'([A-Z])'), r'_\1').toLowerCase()];

    return ExtractionResult(
      type: getProp('type') as String? ?? 'unknown',
      summary: getProp('summary') as String? ?? '',
      personName: getProp('personName') as String?,
      taskDescription: getProp('taskDescription') as String?,
      remindAt: getProp('remindAt') as String?,
      insightDetail: getProp('insightDetail') as String?,
      spinoReaction: getProp('spinoReaction') as String?,
      spinoNotification: getProp('spinoNotification') as String?,
      globalAction: getProp('globalAction') as String?,
    );
  }

  factory ExtractionResult.unknown(String rawText) => ExtractionResult(
        type: 'unknown',
        summary: rawText,
      );

  bool get isValid => type != 'unknown' && summary.trim().length > 3;
}

class GeminiService {
  String? _apiKey;

  static const String _systemPrompt = '''
CORE TASK:
Decompose the user's input into ALL relevant independent entities. If a user mentions three different things (e.g., a task, a fact about a person, and a general insight), you MUST return THREE different objects in a JSON array.

OUTPUT STRUCTURE (STRICT JSON ARRAY):
[
  {
    "type": "actionable" | "insight" | "pattern",
    "summary": "Clean German summary of this specific thought",
    "personName": "Name or null",
    "taskDescription": "Task details or null",
    "remindAt": "ISO Timestamp or null",
    "spinoNotification": "Charming, short notification text (e.g. 'Digga, nicht den Kaffee vergessen!' or 'Saskia hat morgen B-Day, safe!')",
    "insightDetail": "The specific fact/memory/preference",
    "spinoReaction": "pin" | "catch" | "glow",
    "globalAction": "complete_all_tasks" | null
  }
]

LOGIC RULES:
1. MULTI-EXTRACTION: Return independent objects for each distinct thought.
2. PREFERENCE TRACKING: Capture likes/dislikes as 'insight'.
3. SOCIAL UPSERT: Tag mentions with personName.
4. SPEECH HEALING: Repair German phonetic errors but preserve slang/tone.
5. REACTION SYNC: actionable->pin, insight->catch, pattern->glow.
6. PERSON NORMALIZATION: Use provided context to normalize names.
7. TIMEZONE RESILIENCE: 
   - Use 'Current Local Time' and 'Timezone' context.
   - Return ISO timestamps for 'remindAt'.
   - Default time for dates is 09:00:00.
8. GLOBAL ACTIONS: Handle 'complete_all_tasks' commands.
9. NOTIFICATION RULE: Populate 'spinoNotification' if 'remindAt' exists.
10. DE-DUPLICATION: Only return full sentences/thoughts.
11. FRAGMENTS: Ignore non-informational fragments.
12. VERB PRESERVATION: Include primary verbs in 'actionable' items.
13. ZERO TRUNCATION: Preserve all details.
14. PURE COMMANDS: Use 'unknown' type for commands but keep 'globalAction'.

YOU MUST RETURN RAW JSON ARRAY ONLY. NO MARKDOWN.
''';

  void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;

  Future<List<ExtractionResult>> extractMemory(String userText, {
    List<Map<String, dynamic>>? contextTasks,
    List<String>? personContext,
  }) async {
    if (!isInitialized) return [ExtractionResult.unknown(userText)];

    final now = DateTime.now();
    final timezone = now.timeZoneName;
    final offset = now.timeZoneOffset.inHours;

    String contextStr = "Current Local Time: \${now.toIso8601String()} (Timezone: \$timezone, UTC Offset: \$offset)\n\n";
    
    if (contextTasks != null && contextTasks.isNotEmpty) {
      contextStr += "Context Tasks (Incomplete):\n" + contextTasks.map((t) => "- Task: \${t['task_description']}").join("\n") + "\n\n";
    }
    if (personContext != null && personContext.isNotEmpty) {
      contextStr += "Recently Mentioned People: \${personContext.join(', ')}\n\n";
    }

    final finalUserText = contextStr + "User Input: \$userText";

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': finalUserText},
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        final jsonStart = content.indexOf('[');
        final jsonEnd = content.lastIndexOf(']');
        
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final cleanContent = content.substring(jsonStart, jsonEnd + 1);
          final List<dynamic> parsed = jsonDecode(cleanContent);
          return parsed.map((item) => ExtractionResult.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [ExtractionResult.unknown(userText)];
      }
      return [ExtractionResult.unknown(userText)];
    } catch (e) {
      debugPrint('Extraction Error: \$e');
      return [ExtractionResult.unknown(userText)];
    }
  }

  Future<List<String>> batchExtractPersonInsights({
    required String personName,
    required String rawText,
  }) async {
    if (!isInitialized) return [rawText];

    final prompt = '''
Du analysierst Informationen über eine Person und extrahierst alle wichtigen Fakten, Vorlieben und Erkenntnisse.

Person: $personName
Text: $rawText

Regeln:
1. Extrahiere JEDE relevante Information als separaten Punkt
2. Formuliere als kurze, prägnante Sätze auf Deutsch
3. Erfasse Vorlieben, Abneigungen, Gewohnheiten, wichtige Daten
4. Gib NUR ein JSON-Array zurück: ["Fakt 1", "Fakt 2", ...]
5. KEIN Markdown, NUR das JSON-Array

Beispiel-Output: ["Mag Kaffee schwarz", "Hat einen Hund namens Max", "Geburtstag am 15. März"]
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.2,
          'max_tokens': 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        final jsonStart = content.indexOf('[');
        final jsonEnd = content.lastIndexOf(']');
        
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final cleanContent = content.substring(jsonStart, jsonEnd + 1);
          final List<dynamic> parsed = jsonDecode(cleanContent);
          return parsed.map((e) => e.toString()).toList();
        }
      }
      return [rawText];
    } catch (e) {
      debugPrint('Person insight extraction error: $e');
      return [rawText];
    }
  }

  Future<String> querySecondBrain({
    required String question,
    required List<String> recentMemories,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    if (!isInitialized) return 'Please configure your Groq API key in Settings.';

    final contextInfo = recentMemories.isEmpty ? "No memories found." : recentMemories.take(15).join('\n- ');
    
    final prompt = '''
Du bist "Remis zweites Gehirn". Du bist eine authentische, direkte Stimme im Kopf des Nutzers. 
Kontext:
- \$contextInfo

Regeln:
1. Maximal direkt.
2. Echte Konversation (Whatsapp-Stil).
3. Detailgenauigkeit bei sozialen Fakten.
4. Sprache: DEUTSCH.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': prompt},
            ...chatHistory,
            {'role': 'user', 'content': question},
          ],
          'temperature': 0.4,
          'max_tokens': 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return 'Error querying brain.';
    } catch (e) {
      return 'Error: \$e';
    }
  }
}
