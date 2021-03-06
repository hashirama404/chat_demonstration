import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final orgName = 'MIT';
final _fireStore = FirebaseFirestore.instance;
User currentUser;
ScrollController _scrollController = ScrollController();
DocumentSnapshot store;

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  DocumentSnapshot userData;
  ChatScreen(String subject, DocumentSnapshot userData) {
    this.userData = userData;
    subjectName = subject;
  }
  String subjectName;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _formKey = GlobalKey<FormState>();

  final messageTextController = TextEditingController();
  String messageText;

  @override
  void initState() {
    currentUser = FirebaseAuth.instance.currentUser;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              'images/chat.jpg',
              fit: BoxFit.fill,
            )),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.red,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                Text(
                  orgName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MessagesStream(widget.subjectName, widget.userData),
                  Container(
                    padding: EdgeInsets.only(bottom: 10, right: 5, left: 15),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        top: BorderSide(color: Colors.black12, width: 2.0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: messageTextController,
                                onChanged: (value) {
                                  messageText = value;
                                },
                                validator: (val) {
                                  if (val.trim().length == 0) {
                                    return "The message cannot be empty";
                                  } else {
                                    return null;
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: "Enter your message here",
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              _scrollController.animateTo(
                                0.0,
                                curve: Curves.easeOut,
                                duration: const Duration(milliseconds: 200),
                              );
                              messageTextController.clear();
                              _fireStore
                                  .collection('messages' + widget.subjectName)
                                  .add({
                                'text': messageText,
                                'sender': widget.userData.data()['firstName'] +
                                    " " +
                                    widget.userData.data()['lastName'],
                                'isInstructor':
                                    widget.userData.data()['isInstructor'],
                                'date':
                                    DateTime.now().toIso8601String().toString(),
                              });
                              //messageText + loggedInUser.email
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MessagesStream extends StatelessWidget {
  String subjectName;
  DocumentSnapshot userData;
  MessagesStream(String subject, DocumentSnapshot userData) {
    this.userData = userData;
    subjectName = subject;
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore
          .collection('messages' + subjectName)
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        //this is flutter's async snapshot which is different from the query snapshot we use above.
        if (!snapshot.hasData) {
          return Center(
            child: Container(
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          );
        }
        final messages = snapshot.data.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.data()['text'];
          final messageSender = message.data()['sender'];
          final isInstructor = message.data()['isInstructor'];
          final messageBubble = MessageBubble(
            isInstructor: isInstructor,
            sender: messageSender,
            text: messageText,
            isMe: userData.data()['firstName'] +
                    " " +
                    userData.data()['lastName'] ==
                messageSender,
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            controller: _scrollController,
            reverse: true,
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe, this.isInstructor});
  bool isInstructor;
  final bool isMe;
  final String sender;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: isInstructor ? Colors.blue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Text(
                '$text',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
