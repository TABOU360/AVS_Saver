import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat.dart';

class ChatScreen extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;

  ChatScreen({required this.currentUserId, required this.otherUserId});

  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat avec $otherUserId')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(currentUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    return ListTile(title: Text(msg['text']));
                  },
                );
              },
            ),
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Entrez un message'),
            onSubmitted: (text) {
              _chatService.sendMessage(otherUserId, text, currentUserId);
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }
}