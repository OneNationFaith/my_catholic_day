import '../models/catholic_day.dart';
import '../models/liturgical_celebration.dart';

/// Fixed-date celebrations used by the Catholic Day Engine.
///
/// This is the beginning of the United States liturgical calendar.
/// Movable celebrations such as Easter, Pentecost, Corpus Christi,
/// and Christ the King will be calculated separately.
const List<LiturgicalCelebration> fixedLiturgicalCelebrations = [
  // JANUARY

  LiturgicalCelebration(
    name: 'Solemnity of Mary, the Holy Mother of God',
    month: 1,
    day: 1,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'Mary, the Holy Mother of God',
    isHolyDayOfObligation: true,
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saints Basil the Great and Gregory Nazianzen',
    month: 1,
    day: 2,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saints Basil the Great and Gregory Nazianzen',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Elizabeth Ann Seton',
    month: 1,
    day: 4,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Elizabeth Ann Seton',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint John Neumann, Bishop',
    month: 1,
    day: 5,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint John Neumann',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Anthony, Abbot',
    month: 1,
    day: 17,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Anthony the Abbot',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Agnes, Virgin and Martyr',
    month: 1,
    day: 21,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Agnes',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Conversion of Saint Paul the Apostle',
    month: 1,
    day: 25,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'Saint Paul the Apostle',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saints Timothy and Titus, Bishops',
    month: 1,
    day: 26,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saints Timothy and Titus',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Thomas Aquinas, Priest and Doctor',
    month: 1,
    day: 28,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Thomas Aquinas',
  ),

  // FEBRUARY

  LiturgicalCelebration(
    name: 'Feast of the Presentation of the Lord',
    month: 2,
    day: 2,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Agatha, Virgin and Martyr',
    month: 2,
    day: 5,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Agatha',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Scholastica, Virgin',
    month: 2,
    day: 10,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Scholastica',
  ),

  LiturgicalCelebration(
    name: 'Optional Memorial of Our Lady of Lourdes',
    month: 2,
    day: 11,
    rank: CelebrationRank.optionalMemorial,
    color: LiturgicalColor.white,
    saintName: 'Our Lady of Lourdes',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Chair of Saint Peter the Apostle',
    month: 2,
    day: 22,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'Saint Peter the Apostle',
  ),

  // MARCH

  LiturgicalCelebration(
    name: 'Memorial of Saint Katharine Drexel, Virgin',
    month: 3,
    day: 3,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Katharine Drexel',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of Saint Joseph, Spouse of the Blessed Virgin Mary',
    month: 3,
    day: 19,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'Saint Joseph',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of the Annunciation of the Lord',
    month: 3,
    day: 25,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
  ),

  // APRIL

  LiturgicalCelebration(
    name: 'Memorial of Saint Stanislaus, Bishop and Martyr',
    month: 4,
    day: 11,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Stanislaus',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Mark, Evangelist',
    month: 4,
    day: 25,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Mark',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Catherine of Siena, Virgin and Doctor',
    month: 4,
    day: 29,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Catherine of Siena',
  ),

  // MAY

  LiturgicalCelebration(
    name: 'Optional Memorial of Saint Joseph the Worker',
    month: 5,
    day: 1,
    rank: CelebrationRank.optionalMemorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Joseph the Worker',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saints Philip and James, Apostles',
    month: 5,
    day: 3,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saints Philip and James',
  ),

  LiturgicalCelebration(
    name: 'Optional Memorial of Our Lady of Fatima',
    month: 5,
    day: 13,
    rank: CelebrationRank.optionalMemorial,
    color: LiturgicalColor.white,
    saintName: 'Our Lady of Fatima',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Visitation of the Blessed Virgin Mary',
    month: 5,
    day: 31,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'The Blessed Virgin Mary',
  ),

  // JUNE

  LiturgicalCelebration(
    name: 'Memorial of Saint Justin, Martyr',
    month: 6,
    day: 1,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Justin',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Boniface, Bishop and Martyr',
    month: 6,
    day: 5,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Boniface',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Barnabas, Apostle',
    month: 6,
    day: 11,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Barnabas',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of the Nativity of Saint John the Baptist',
    month: 6,
    day: 24,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'Saint John the Baptist',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of Saints Peter and Paul, Apostles',
    month: 6,
    day: 29,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.red,
    saintName: 'Saints Peter and Paul',
  ),

  // JULY

  LiturgicalCelebration(
    name: 'Optional Memorial of Saint Junípero Serra, Priest',
    month: 7,
    day: 1,
    rank: CelebrationRank.optionalMemorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Junípero Serra',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Thomas, Apostle',
    month: 7,
    day: 3,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Thomas the Apostle',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Benedict, Abbot',
    month: 7,
    day: 11,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Benedict',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Kateri Tekakwitha, Virgin',
    month: 7,
    day: 14,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Kateri Tekakwitha',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Bonaventure, Bishop and Doctor',
    month: 7,
    day: 15,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Bonaventure',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Mary Magdalene',
    month: 7,
    day: 22,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'Saint Mary Magdalene',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint James, Apostle',
    month: 7,
    day: 25,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint James the Apostle',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saints Martha, Mary and Lazarus',
    month: 7,
    day: 29,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saints Martha, Mary and Lazarus',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Ignatius of Loyola, Priest',
    month: 7,
    day: 31,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Ignatius of Loyola',
  ),

  // AUGUST

  LiturgicalCelebration(
    name: 'Memorial of Saint Alphonsus Liguori, Bishop and Doctor',
    month: 8,
    day: 1,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Alphonsus Liguori',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint John Vianney, Priest',
    month: 8,
    day: 4,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint John Vianney',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Transfiguration of the Lord',
    month: 8,
    day: 6,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Dominic, Priest',
    month: 8,
    day: 8,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Dominic',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Lawrence, Deacon and Martyr',
    month: 8,
    day: 10,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Lawrence',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Clare, Virgin',
    month: 8,
    day: 11,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Clare',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of the Assumption of the Blessed Virgin Mary',
    month: 8,
    day: 15,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'The Blessed Virgin Mary',
    isHolyDayOfObligation: true,
  ),

  LiturgicalCelebration(
    name: 'Memorial of the Queenship of the Blessed Virgin Mary',
    month: 8,
    day: 22,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'The Blessed Virgin Mary',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Bartholomew, Apostle',
    month: 8,
    day: 24,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Bartholomew',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Augustine, Bishop and Doctor',
    month: 8,
    day: 28,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Augustine',
  ),

  LiturgicalCelebration(
    name: 'Memorial of the Passion of Saint John the Baptist',
    month: 8,
    day: 29,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint John the Baptist',
  ),

  // SEPTEMBER

  LiturgicalCelebration(
    name: 'Feast of the Nativity of the Blessed Virgin Mary',
    month: 9,
    day: 8,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'The Blessed Virgin Mary',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint John Chrysostom, Bishop and Doctor',
    month: 9,
    day: 13,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint John Chrysostom',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Exaltation of the Holy Cross',
    month: 9,
    day: 14,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
  ),

  LiturgicalCelebration(
    name: 'Memorial of Our Lady of Sorrows',
    month: 9,
    day: 15,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Our Lady of Sorrows',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Matthew, Apostle and Evangelist',
    month: 9,
    day: 21,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Matthew',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Pius of Pietrelcina, Priest',
    month: 9,
    day: 23,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Pius of Pietrelcina',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saints Michael, Gabriel and Raphael, Archangels',
    month: 9,
    day: 29,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'Saints Michael, Gabriel and Raphael',
  ),

  // OCTOBER

  LiturgicalCelebration(
    name: 'Memorial of Saint Thérèse of the Child Jesus, Virgin and Doctor',
    month: 10,
    day: 1,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Thérèse of Lisieux',
  ),

  LiturgicalCelebration(
    name: 'Memorial of the Holy Guardian Angels',
    month: 10,
    day: 2,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'The Holy Guardian Angels',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Francis of Assisi',
    month: 10,
    day: 4,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Francis of Assisi',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Our Lady of the Rosary',
    month: 10,
    day: 7,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Our Lady of the Rosary',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Luke, Evangelist',
    month: 10,
    day: 18,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Luke',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saints Simon and Jude, Apostles',
    month: 10,
    day: 28,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saints Simon and Jude',
  ),

  // NOVEMBER

  LiturgicalCelebration(
    name: 'Solemnity of All Saints',
    month: 11,
    day: 1,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'All Saints',
    isHolyDayOfObligation: true,
  ),

  LiturgicalCelebration(
    name: 'Commemoration of All the Faithful Departed',
    month: 11,
    day: 2,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.violet,
    saintName: 'All Souls',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Dedication of the Lateran Basilica',
    month: 11,
    day: 9,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Leo the Great, Pope and Doctor',
    month: 11,
    day: 10,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Leo the Great',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Martin of Tours, Bishop',
    month: 11,
    day: 11,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Martin of Tours',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Cecilia, Virgin and Martyr',
    month: 11,
    day: 22,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Cecilia',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Andrew, Apostle',
    month: 11,
    day: 30,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Andrew',
  ),

  // DECEMBER

  LiturgicalCelebration(
    name: 'Memorial of Saint Francis Xavier, Priest',
    month: 12,
    day: 3,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint Francis Xavier',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of the Immaculate Conception of the Blessed Virgin Mary',
    month: 12,
    day: 8,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'The Blessed Virgin Mary',
    isHolyDayOfObligation: true,
  ),

  LiturgicalCelebration(
    name: 'Optional Memorial of Our Lady of Loreto',
    month: 12,
    day: 10,
    rank: CelebrationRank.optionalMemorial,
    color: LiturgicalColor.white,
    saintName: 'Our Lady of Loreto',
  ),

  LiturgicalCelebration(
    name: 'Feast of Our Lady of Guadalupe',
    month: 12,
    day: 12,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'Our Lady of Guadalupe',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint Lucy, Virgin and Martyr',
    month: 12,
    day: 13,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.red,
    saintName: 'Saint Lucy',
  ),

  LiturgicalCelebration(
    name: 'Memorial of Saint John of the Cross, Priest and Doctor',
    month: 12,
    day: 14,
    rank: CelebrationRank.memorial,
    color: LiturgicalColor.white,
    saintName: 'Saint John of the Cross',
  ),

  LiturgicalCelebration(
    name: 'Solemnity of the Nativity of the Lord',
    month: 12,
    day: 25,
    rank: CelebrationRank.solemnity,
    color: LiturgicalColor.white,
    saintName: 'Jesus Christ',
    isHolyDayOfObligation: true,
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint Stephen, the First Martyr',
    month: 12,
    day: 26,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'Saint Stephen',
  ),

  LiturgicalCelebration(
    name: 'Feast of Saint John, Apostle and Evangelist',
    month: 12,
    day: 27,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.white,
    saintName: 'Saint John the Apostle',
  ),

  LiturgicalCelebration(
    name: 'Feast of the Holy Innocents, Martyrs',
    month: 12,
    day: 28,
    rank: CelebrationRank.feast,
    color: LiturgicalColor.red,
    saintName: 'The Holy Innocents',
  ),
];

/// Finds a fixed celebration for the supplied date.
///
/// Returns null when no fixed celebration is stored for that date.
LiturgicalCelebration? fixedCelebrationFor(DateTime date) {
  for (final celebration in fixedLiturgicalCelebrations) {
    if (celebration.occursOn(date)) {
      return celebration;
    }
  }

  return null;
}