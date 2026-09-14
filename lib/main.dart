import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(home: M3uPlayerApp()));

class Channel {
  final String title;
  final String url;
  Channel({required this.title, required this.url});
}

class M3uPlayerApp extends StatefulWidget {
  const M3uPlayerApp({super.key});

  @override
  State<M3uPlayerApp> createState() => _M3uPlayerAppState();
}

class _M3uPlayerAppState extends State<M3uPlayerApp> {
  List<Channel> channels = [];

  Future<void> pickAndParseFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      
      setState(() {
        channels = parseM3u(content);
      });
    }
  }

  List<Channel> parseM3u(String content) {
    List<Channel> list = [];
    List<String> lines = content.split('\n');
    String title = '';

    for (String line in lines) {
      line = line.trim();
      if (line.startsWith('#EXTINF:')) {
        int commaIndex = line.indexOf(',');
        if (commaIndex != -1) title = line.substring(commaIndex + 1).trim();
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        list.add(Channel(title: title.isNotEmpty ? title : 'قناة', url: line));
        title = '';
      }
    }
    return list;
  }

  Future<void> playInExternalPlayer(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط القناة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشغل M3U'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: pickAndParseFile,
          )
        ],
      ),
      body: channels.isEmpty
          ? const Center(
              child: Text('اضغط على أيقونة المجلد في الأعلى لتحديد ملف M3U'),
            )
          : ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final item = channels[index];
                return ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.green, size: 32),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => playInExternalPlayer(item.url),
                );
              },
            ),
    );
  }
}
