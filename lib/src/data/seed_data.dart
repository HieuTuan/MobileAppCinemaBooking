part of '../app.dart';

final List<Showtime> _showtimes = [
  const Showtime(
    id: 'ST-1',
    branch: 'Lux Quan 1',
    hall: 'Luxe Hall',
    date: '29/05/2026',
    time: '19:30',
  ),
  const Showtime(
    id: 'ST-2',
    branch: 'IMAX Landmark 81',
    hall: 'IMAX Sapphire',
    date: '29/05/2026',
    time: '21:45',
  ),
  const Showtime(
    id: 'ST-3',
    branch: 'Royal Suite Tay Ho',
    hall: 'Velvet Bed',
    date: '30/05/2026',
    time: '20:15',
  ),
];

final Map<String, int> _foodMenu = {
  'Gourmet Gold Popcorn': 99000,
  'Champagne Rose nhap khau Phap': 390000,
  'Family Royal Combo': 180000,
  'Chocolate Truffle Cinema Box': 145000,
};

List<Movie> _seedMovies() {
  return [
    Movie(
      id: 'DUNE2',
      title: 'Dune: Part Two',
      genre: 'Khoa hoc vien tuong',
      year: 2024,
      director: 'Denis Villeneuve',
      cast: 'Timothee Chalamet, Zendaya, Rebecca Ferguson',
      duration: 166,
      posterUrl:
          'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      coverUrl:
          'https://image.tmdb.org/t/p/w1280/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg',
      synopsis:
          'Paul Atreides lien minh voi nguoi Fremen trong hanh trinh tra thu va dinh doat tuong lai Arrakis.',
      vipGold: true,
    ),
    Movie(
      id: 'OPPEN',
      title: 'Oppenheimer',
      genre: 'Tieu su chinh kich',
      year: 2023,
      director: 'Christopher Nolan',
      cast: 'Cillian Murphy, Emily Blunt, Robert Downey Jr.',
      duration: 181,
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      coverUrl:
          'https://image.tmdb.org/t/p/w1280/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
      synopsis:
          'Chan dung nha vat ly J. Robert Oppenheimer va cai gia cua tri tue trong thoi dai hat nhan.',
      vipGold: true,
    ),
    Movie(
      id: 'INSIDE2',
      title: 'Inside Out 2',
      genre: 'Hoat hinh gia dinh',
      year: 2024,
      director: 'Kelsey Mann',
      cast: 'Amy Poehler, Maya Hawke, Kensington Tallman',
      duration: 96,
      posterUrl:
          'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
      coverUrl:
          'https://image.tmdb.org/t/p/w1280/stKGOm8UyhuLPR9sZLjs5AkmncA.jpg',
      synopsis:
          'Nhung cam xuc moi xuat hien khi Riley buoc vao tuoi thieu nien.',
      vipGold: false,
    ),
    Movie(
      id: 'FURIOSA',
      title: 'Furiosa: A Mad Max Saga',
      genre: 'Hanh dong',
      year: 2024,
      director: 'George Miller',
      cast: 'Anya Taylor-Joy, Chris Hemsworth',
      duration: 148,
      posterUrl:
          'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xceZprc.jpg',
      coverUrl:
          'https://image.tmdb.org/t/p/w1280/wNAhuOZ3Zf84jCIlrcI6JhgmY5q.jpg',
      synopsis:
          'Furiosa tim duong tro ve que huong giua vung dat hoang hau tan the.',
      vipGold: false,
    ),
  ];
}
