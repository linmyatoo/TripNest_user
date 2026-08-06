import 'dart:convert';


import '../../models/booking.dart';
import 'auth_service.dart';
import 'booking_service.dart';
import 'session.dart';
import 'http_client.dart';
import '../config/api_endpoints.dart';

/// Model for a chat message
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: (json['senderName'] ?? 'Unknown') as String,
      senderEmail: (json['senderEmail'] ?? '') as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Model for last message
class LastMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;

  LastMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderEmail: json['senderEmail'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Model for chat room
class ChatRoom {
  final String id;
  final String eventId;
  final String eventTitle;
  final String? eventImageUrl;
  final int memberCount;
  final DateTime createdAt;
  final LastMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventImageUrl,
    required this.memberCount,
    required this.createdAt,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String,
      eventImageUrl: json['eventImageUrl'] as String?,
      memberCount: json['memberCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Model for chat room member
class Member {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime joinedAt;

  Member({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}

class ChatService {
  /// Leave a chat room
  static Future<void> leaveChatRoom(String roomId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await Http.client.post(
        Uri.parse('$baseUrl/chat/rooms/$roomId/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Session.checkResponse(response);


      if (response.statusCode == 200) {
        // Successfully left the chat room
        return;
      } else if (response.statusCode == 403) {
        throw Exception('You are not a member of this chat room');
      } else {
        throw Exception('Failed to leave chat room');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static const String baseUrl = ApiEndpoints.baseUrl;

  /// Get all chat rooms user is a member of
  static Future<List<ChatRoom>> getChatRooms() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await Http.client.get(
        Uri.parse('$baseUrl/chat/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Session.checkResponse(response);


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomsList = data['rooms'] as List<dynamic>;
        return roomsList
            .map((room) => ChatRoom.fromJson(room as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load chat rooms');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Chat rooms for events the user actually booked.
  ///
  /// `GET /chat/rooms` returns every room the backend considers the user a
  /// member of, and membership does not track bookings: a room could show up
  /// for an event the user never booked, or linger after a booking was
  /// cancelled. Chat is a perk of booking, so gate the list on the user's own
  /// bookings and drop CANCELLED ones.
  ///
  /// Throws if either call fails — a failed bookings fetch must not silently
  /// fall back to showing ungated rooms.
  static Future<List<ChatRoom>> getBookedChatRooms() async {
    final results = await Future.wait([
      getChatRooms(),
      BookingService.getMyBookings(),
    ]);

    final rooms = results[0] as List<ChatRoom>;
    final bookings = results[1] as List<Booking>;

    final bookedEventIds = bookings
        .where((booking) => booking.status.toUpperCase() != 'CANCELLED')
        .map((booking) => booking.eventId)
        .where((eventId) => eventId.isNotEmpty)
        .toSet();

    return rooms
        .where((room) => bookedEventIds.contains(room.eventId))
        .toList();
  }

  /// Get messages from a specific chat room
  static Future<List<Message>> getChatMessages(
    String roomId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (before != null) {
        queryParams['before'] = before;
      }

      final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/messages')
          .replace(queryParameters: queryParams);

      final response = await Http.client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Session.checkResponse(response);


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messagesList = data['messages'] as List<dynamic>;
        return messagesList
            .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        throw Exception('You are not a member of this chat room');
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get members from a specific chat room
  static Future<List<Member>> getChatMembers(String roomId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await Http.client.get(
        Uri.parse('$baseUrl/chat/rooms/$roomId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Session.checkResponse(response);


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final membersList = data['members'] as List<dynamic>;
        return membersList
            .map((member) => Member.fromJson(member as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        throw Exception('You are not a member of this chat room');
      } else {
        throw Exception('Failed to load members');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Send a message to a chat room
  static Future<Message> sendMessage(
    String roomId,
    String content,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (content.isEmpty) {
        throw Exception('Message content cannot be empty');
      }

      if (content.length > 2000) {
        throw Exception('Message content cannot exceed 2000 characters');
      }

      final response = await Http.client.post(
        Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      Session.checkResponse(response);


      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['message'] as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Invalid message');
      } else if (response.statusCode == 403) {
        throw Exception('You are not a member of this chat room');
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
