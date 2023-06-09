import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omnitalk_sdk/omnitalk_sdk.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChattingDemo extends StatefulWidget {
  const ChattingDemo({super.key});

  @override
  State<ChattingDemo> createState() => _ChattingDemoState();
}

class _ChattingDemoState extends State<ChattingDemo> {
  Omnitalk omnitalk;
  String sessionId = '';
  String userId = '';
  List listMessage = [];

  final TextEditingController _userInputController = TextEditingController();
  final TextEditingController _secretInputController = TextEditingController();
  final TextEditingController _chattingInputController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FocusNode _userFocusnode = FocusNode();
  final FocusNode _secretFocusnode = FocusNode();

  bool _isUserInputDone = false;
  bool _isSecretInputDone = false;
  bool _isUserInputVisible = true;
  bool _isButtonEnabled = true;

  List partilist = [];

  onDataRoomJoin(String username) {
    print('"$username" Joined Chatting Room');
    Fluttertoast.showToast(
        msg: "$username joined the room",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        fontSize: 16,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT);
  }

  onMessageReceived(event) {
    listMessage.add(event);
    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut);
  }

  onLeaveEvent(String username) {
    print('User "$username" Left Chatting Room');
    Fluttertoast.showToast(
        msg: "$username left the room",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        fontSize: 16,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT);
  }

  getParticipants(event) async {
    // await omnitalk.dataChannelPartiList();
  }

  addParticipants(event) {
    partilist = event["participants"];
    print(partilist);
  }

  _onButtonPressed() async {
    await _onCreateSession();
    await _onDataRoom();
    setState(() {
      _isButtonEnabled = false;
    });
  }

  _onCreateSession() async {
    await omnitalk.getPermission();
    userId = _userInputController.text;
    var session = await omnitalk.createSession(userId);
    sessionId = session["session"];
    // await omnitalk.dataChannelPartiList();
  }

  _onDataRoom() async {
    // pass room_type as dataroom (default : videoroom), subject, secret
    var secret = _secretInputController.text;
    var roomObj =
        await omnitalk.createRoom(room_type: "dataroom", secret: secret);
    var roomId = roomObj["room_id"];
    await omnitalk.joinRoom(room_id: roomId, secret: secret);
    _userFocusnode.unfocus(
        disposition: UnfocusDisposition.previouslyFocusedChild);
    _secretFocusnode.unfocus(
        disposition: UnfocusDisposition.previouslyFocusedChild);
    setState(() {
      _isUserInputDone = true;
      _isSecretInputDone = true;
    });
  }

  void _onTypeChattingPressed() async {
    if (_chattingInputController.text.isNotEmpty) {
      var message = _chattingInputController.text;

      await omnitalk.sendDataMessage(message: message);
      _chattingInputController.clear();
      setState(() {
        _isUserInputVisible = false;
      });
    } else {
      Fluttertoast.showToast(
          msg: "nothing to send",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          fontSize: 16,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT);
    }
  }

  _onLeave() async {
    await omnitalk.leave(sessionId);
    _userInputController.dispose();
    _secretInputController.dispose();
    _chattingInputController.dispose();
  }

  _ChattingDemoState()
      : omnitalk = Omnitalk("FM51-HITX-IBPG-QN7H", "FWIWblAEXpbIims") {
    omnitalk.onDataMessage = (event) async {
      switch (event["textroom"]) {
        case "join":
          onDataRoomJoin(event["username"]);
          getParticipants(event);
          break;
        case "message":
          setState(() {
            onMessageReceived(event);
          });
          break;

        case "parti_list":
          addParticipants(event);
          print(partilist);
          break;
        case "leave":
          onLeaveEvent(event["username"]);
          break;
        default:
          break;
      }
    };
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Column(
        children: [
          Visibility(
            visible: _isUserInputVisible,
            child: Row(
              children: [
                userInput(),
                const SizedBox(
                  width: 10,
                ),
                secretInput(),
                const SizedBox(
                  width: 10,
                ),
                createRoomButton()
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          displayChatting(),
        ],
      ),
      bottomNavigationBar: appBottomBar(),
    );
  }

  BottomAppBar appBottomBar() {
    return BottomAppBar(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chattingInputController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  hintText: "Type your message",
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16.0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orangeAccent))),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: _onTypeChattingPressed,
            color: Colors.orange[800],
          )
        ],
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        "Chatting Room",
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.orange[800],
      foregroundColor: Colors.white,
      actions: <Widget>[
        IconButton(
          onPressed: _onLeave,
          icon: const Icon(Icons.exit_to_app_outlined),
          tooltip: 'Leave',
        )
      ],
    );
  }

  Expanded displayChatting() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(10),
        child: chattingListMessage(listMessage),
      ),
    );
  }

  ElevatedButton createRoomButton() {
    return ElevatedButton(
      onPressed: _isButtonEnabled ? _onButtonPressed : null,
      style: ButtonStyle(
          backgroundColor: _isButtonEnabled
              ? MaterialStateProperty.all(Colors.orange[800])
              : MaterialStateProperty.all(Colors.grey)),
      child: const Text('Create Room'),
    );
  }

  Expanded secretInput() {
    return Expanded(
      child: TextField(
        controller: _secretInputController,
        focusNode: _secretFocusnode,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.security_rounded,
                color: _isSecretInputDone ? Colors.grey : Colors.orange),
            hintText: "Secret",
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent))),
        enabled: !_isSecretInputDone,
      ),
    );
  }

  Expanded userInput() {
    return Expanded(
      child: TextField(
        controller: _userInputController,
        focusNode: _userFocusnode,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.perm_identity,
              color: _isUserInputDone ? Colors.grey : Colors.orange,
            ),
            hintText: "User Id",
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent))),
        enabled: !_isUserInputDone,
      ),
    );
  }

  Widget chattingListMessage(listMessage) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) => buildItem(index, listMessage),
      itemCount: listMessage.length,
      reverse: false,
      controller: _scrollController,
    );
  }

  buildItem(index, listMessage) {
    Map<String, dynamic> message = listMessage[index];
    DateTime utc = DateTime.parse(message["date"]);
    DateTime localtime = utc.toLocal();
    String time = DateFormat('HH:mm:ss').format(localtime);
    String from = message["from"];

    return Row(
      mainAxisAlignment:
          from == userId ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (from != userId)
          CircleAvatar(
            child: Text(from),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: from == userId ? Colors.orange[100] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft:
                    from == userId ? const Radius.circular(16) : Radius.zero,
                topRight:
                    from == userId ? Radius.zero : const Radius.circular(16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: from == userId
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  message["text"],
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (from == userId)
          CircleAvatar(
            child: Text(from),
          ),
      ],
    );
  }
}
