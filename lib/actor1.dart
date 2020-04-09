// Based on [this](https://github.com/winksaville/dart-isolate-example)

// Currently creates two actors and they can communicate with the "master".
// The next goal is to implement the "connect" command so the two actors
// can communicate directly with them selves.

import 'dart:isolate';

/// Commands actors support
/// A message is a Map with a key of ActorCmd whose
/// name is one of the following enumerations
enum ActorCmd {
  op,                         /// Operation
  sendPort,                   /// ActorCmd.data is the SendPort
  data,                       /// ActorCmd.data is some data
  connectToPeer,              /// ActorCmd.data is SendPort
  connectFromPeer,            /// ActorCmd.data is SendPort
  connected,                  /// ActorCmd.data empty
  peerIsConnected,            /// ActorCmd.data is SendPort
  connectedToPeer,            /// ActorCmd.data empty
  startEcho,                  /// ActorCmd.data data
  echo,                       /// ActorCmd.data data
  stopEcho,                   /// ActorCmd.data empty
  stopEchoResult,             /// ActorCmd.data echoCounter
}

/// Actor that can process messages
abstract class ActorBase {
  /// Contruct an actor passing a SendPort which is used
  /// by the client to send messages to the ReceivePort.
  ActorBase(this.name, this._toMasterSendPort);

  String name;
  Isolate isolate;

  final SendPort _toMasterSendPort;
  ReceivePort _fromMasterReceivePort;

  /// Start the actor. When the actor starts _enter will
  /// it will create a ReceivePort and send the SendPort
  /// back to the master.
  Future<void> start({bool local=false}) async {
    if (local) {
      print('$name: local');
      isolate = Isolate.current;
      _entryPoint(this);
    } else {
      print('$name: isolate');
      isolate = await Isolate.spawn<ActorBase>(ActorBase._entryPoint, this);
    }
  }

  /// Stop the actor immediately if its not a local actor.
  void stop() { //SendPort toActorSendPort, ReceivePort fromActorReceivePort) {
    // Handle isolate being null
    if ((isolate != null) && (isolate != Isolate.current)) {
      isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Invoked by when the actor starts.
  static void _entryPoint(ActorBase actor) {
    actor._enter();
    actor._begin();
    actor._listen();
    assert(actor._fromMasterReceivePort != null);
    print('${actor.name}: sending ActorCmd.connected');
    actor._toMasterSendPort.send(<ActorCmd, dynamic>{
      ActorCmd.op: ActorCmd.connected,
    });
  }

  /// Called once when Actor is first invoked and usually
  /// Sets up communication with the partner
  void _enter() {
    // Create a port that will receive messages
    _fromMasterReceivePort =  ReceivePort();
    _toMasterSendPort.send(<ActorCmd, dynamic>{
      ActorCmd.op: ActorCmd.sendPort,
      ActorCmd.data: _fromMasterReceivePort.sendPort
    });
  }

  /// Invoked once when the actor is first started after
  /// _enter and before the first call to _process.
  void _begin() {}

  void _listen() {
    assert(_fromMasterReceivePort != null);
    _fromMasterReceivePort.listen(_process);
  }

  /// Invoked everytime a message arrives from the partner
  /// and must be overridden
  void _process(dynamic msg);
}

class MyActor extends ActorBase {
  MyActor(String name, SendPort masterPort) : super(name, masterPort);

  SendPort _peerSendPort;
  ReceivePort _peerReceivePort;

  int echoCounter = 0;
  bool echoing = false;

  @override
  void _process(dynamic msg) {
    switch (msg[ActorCmd.op] as ActorCmd) {
      case ActorCmd.sendPort:
        print('$name._process: sendPort data=${msg[ActorCmd.data]}');
        break;
      case ActorCmd.connectToPeer:
        // Master asking us to connect to a peer
        print('$name._process:+ connectToPeer data=${msg[ActorCmd.data]}');
        if (_peerSendPort == null) {
          print('$name._process:+ connectToPeer _peerSendPort == null');
          assert(msg[ActorCmd.data] is SendPort);
          _peerSendPort = msg[ActorCmd.data] as SendPort;

          // Send the peer ReceivePort.sendPort so the peer can send to us
          _peerReceivePort = ReceivePort();
          _peerSendPort.send(<ActorCmd, dynamic> {
            ActorCmd.op: ActorCmd.connectFromPeer,
            ActorCmd.data: _peerReceivePort.sendPort,
          });

          _peerReceivePort.listen(_process);
          print('$name._process:- connectToPeer _peerSendPort == null');
        } else {
          print('$name._process:+ connectToPeer _peerSendPort != null Already connected');
          _peerSendPort.send(<ActorCmd, dynamic> {
            ActorCmd.op: ActorCmd.data,
            ActorCmd.data: '$name We are connected',
          });
          print('$name._process:- connectToPeer _peerSendPort != null Already connected');
        }
        print('$name._process:- connectToPeer data=${msg[ActorCmd.data]}');
        break;
      case ActorCmd.peerIsConnected:
        print('$name._process:+ peerIsConnected msg=$msg');
        assert(_peerSendPort != null);
        assert(msg[ActorCmd.data] is SendPort);
        _peerSendPort = msg[ActorCmd.data] as SendPort;
        print('$name._process: 1 peerIsConnected');
        _toMasterSendPort.send(<ActorCmd, dynamic>{
          ActorCmd.op: ActorCmd.connectedToPeer
        });
        print('$name._process:- peerIsConnected msg=$msg');
        break;
      case ActorCmd.connectFromPeer:
        // Peer asking us to connect to them
        print('$name._process:+ connectFromPeer data=${msg[ActorCmd.data]}');
        if (_peerSendPort == null) {
          print('$name._process:+ connectFromPeer _peerSendPort == null');
          assert(msg[ActorCmd.data] is SendPort);
          _peerSendPort = msg[ActorCmd.data] as SendPort;

          // Send the peer ReceivePort.sendPort via ActorCmd.connected
          // TODO(wink): add our name and/or a GUID?
          _peerReceivePort = ReceivePort();
          _peerSendPort.send(<ActorCmd, dynamic> {
            ActorCmd.op: ActorCmd.peerIsConnected,
            ActorCmd.data: _peerReceivePort.sendPort,
          });
          _peerReceivePort.listen(_process);
          print('$name._process:- connectFromPeer _peerSendPort == null');
        } else {
          print('$name._process:+ connectFromPeer _peerSendPort != null Already connected');
          assert(false); // Always fail
          print('$name._process:- connectFromPeer _peerSendPort != null Already connected');
        }
        print('$name._process:- connectFromPeer data=${msg[ActorCmd.data]}');
        break;
      case ActorCmd.connected:
        print('$name._process: connected msg=$msg');
        assert(_peerSendPort != null);
        assert(msg[ActorCmd.data] is SendPort);
        _peerSendPort = msg[ActorCmd.data] as SendPort;
        break;
      case ActorCmd.data:
        print('$name._process: data data=${msg[ActorCmd.data]}');
        break;
      case ActorCmd.startEcho:
        print('$name._process: startEcho $msg');
        echoing = true;
        continue echoLabel;
      echoLabel:
      case ActorCmd.echo:
        if (echoing) {
          //print('$name._process: echo $msg');
          // For now we'll play endless ping pong with our peer passing
          // the msg[ActorCmd.data] back and forth.
          assert(_peerSendPort != null);
          echoCounter += 1;
          _peerSendPort.send(<ActorCmd, dynamic>{
            ActorCmd.op: ActorCmd.echo,
            ActorCmd.data: msg[ActorCmd.data],
          });
        }
        break;
      case ActorCmd.stopEcho:
        print('$name._process: stopEcho $msg');
        // TODO(wink): we need to know who to reply to.
        // We could require a SendPort in every message or
        // some type of Capability/ID to which we could
        // use as a map key to identify whom to send the result.
        // for now we'll assume it was "master".
        echoing = false;
        _toMasterSendPort.send(<ActorCmd, dynamic>{
          ActorCmd.op: ActorCmd.stopEchoResult,
          ActorCmd.data: echoCounter,
        });
        break;
      default:
        print('$name._process: Unknown ActorCmd ${msg[ActorCmd]}');
        break;
    }
  }
}
