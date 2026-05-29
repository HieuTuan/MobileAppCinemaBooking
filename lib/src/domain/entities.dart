part of '../app.dart';

enum UserRole { customer, admin, staff }

enum BookingStatus { active, used, cancelled }

class DemoUser {
  const DemoUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone = '0900 000 000',
    this.memberTier = 'Elite Prestige',
    this.favoriteBranch = 'IMAX Landmark 81',
    this.joinedDate = '29/05/2026',
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String phone;
  final String memberTier;
  final String favoriteBranch;
  final String joinedDate;
}

class Movie {
  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.director,
    required this.cast,
    required this.duration,
    required this.posterUrl,
    required this.coverUrl,
    required this.synopsis,
    required this.vipGold,
  });

  String id;
  String title;
  String genre;
  int year;
  String director;
  String cast;
  int duration;
  String posterUrl;
  String coverUrl;
  String synopsis;
  bool vipGold;
}

class Showtime {
  const Showtime({
    required this.id,
    required this.branch,
    required this.hall,
    required this.date,
    required this.time,
  });

  final String id;
  final String branch;
  final String hall;
  final String date;
  final String time;
}

class Booking {
  Booking({
    required this.id,
    required this.customerName,
    required this.movieTitle,
    required this.showtime,
    required this.seats,
    required this.food,
    required this.total,
    required this.createdAt,
    this.status = BookingStatus.active,
  });

  final String id;
  final String customerName;
  final String movieTitle;
  final Showtime showtime;
  final List<String> seats;
  final List<String> food;
  final int total;
  final DateTime createdAt;
  BookingStatus status;
}
