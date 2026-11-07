import '../models/song.dart';

const mockThumbs = [
  'https://picsum.photos/seed/ryotunes1/300/300',
  'https://picsum.photos/seed/ryotunes2/300/300',
  'https://picsum.photos/seed/ryotunes3/300/300',
  'https://picsum.photos/seed/ryotunes4/300/300',
  'https://picsum.photos/seed/ryotunes5/300/300',
  'https://picsum.photos/seed/ryotunes6/300/300',
];

List<SongItem> mockSongs() => [
  // Tamil / South Indian trending — primary content.
  const SongItem(videoId: 't1', title: 'Kaavaalaa', artists: 'Shilpa Rao', album: 'Jailer', duration: '3:32', thumbnail: 'https://picsum.photos/seed/t1/300/300'),
  const SongItem(videoId: 't2', title: 'Arabic Kuthu', artists: 'Anirudh Ravichander', album: 'Beast', duration: '4:10', thumbnail: 'https://picsum.photos/seed/t2/300/300'),
  const SongItem(videoId: 't3', title: 'Vaathi Coming', artists: 'Anirudh Ravichander', album: 'Master', duration: '3:48', thumbnail: 'https://picsum.photos/seed/t3/300/300'),
  const SongItem(videoId: 't4', title: 'Rowdy Baby', artists: 'Dhanush, Dhee', album: 'Maari 2', duration: '4:06', thumbnail: 'https://picsum.photos/seed/t4/300/300'),
  const SongItem(videoId: 't5', title: 'Jimikki Ponnu', artists: 'Anirudh Ravichander', album: 'Varisu', duration: '3:25', thumbnail: 'https://picsum.photos/seed/t5/300/300'),
  const SongItem(videoId: 'm1', title: 'Manike Mage Hithe', artists: 'Yohani, Satheeshan', album: 'Manike', duration: '3:10', thumbnail: 'https://picsum.photos/seed/m1/300/300'),
  const SongItem(videoId: 'm2', title: 'Pookkal', artists: 'Sid Sriram', album: 'Pookkal', duration: '4:02', thumbnail: 'https://picsum.photos/seed/m2/300/300'),
  const SongItem(videoId: 'm3', title: 'Malare', artists: 'Vijay Yesudas', album: 'Premam', duration: '4:30', thumbnail: 'https://picsum.photos/seed/m3/300/300'),
];

List<BrowseItem> mockAlbums() => [
  const BrowseItem(kind: 'album', id: 'a1', title: 'Afterglow', subtitle: 'Neon Harbor', thumbnail: 'https://picsum.photos/seed/a1/300/300'),
  const BrowseItem(kind: 'album', id: 'a2', title: 'Origami', subtitle: 'Sora & Kite', thumbnail: 'https://picsum.photos/seed/a2/300/300'),
  const BrowseItem(kind: 'album', id: 'a3', title: 'Static Bloom', subtitle: 'Luma', thumbnail: 'https://picsum.photos/seed/a3/300/300'),
];

List<BrowseItem> mockArtists() => [
  const BrowseItem(kind: 'artist', id: 'ar1', title: 'Neon Harbor', subtitle: 'Artist', thumbnail: 'https://picsum.photos/seed/ar1/300/300'),
  const BrowseItem(kind: 'artist', id: 'ar2', title: 'Luma', subtitle: 'Artist', thumbnail: 'https://picsum.photos/seed/ar2/300/300'),
];

List<BrowseItem> mockPlaylists() => [
  const BrowseItem(kind: 'playlist', id: 'p1', title: 'Liked Songs', subtitle: '42 songs', thumbnail: 'https://picsum.photos/seed/p1/300/300'),
  const BrowseItem(kind: 'playlist', id: 'p2', title: 'Chill Evening', subtitle: '18 songs', thumbnail: 'https://picsum.photos/seed/p2/300/300'),
];

HomePage mockHome() => HomePage(
  chips: const ['All', 'Songs', 'Albums', 'Artists'],
  sections: [
    Section(title: 'Continue listening', items: mockSongs().map((s) => BrowseItem(kind: 'song', id: s.videoId, title: s.title, subtitle: s.artists, thumbnail: s.thumbnail, duration: s.duration)).toList()),
    Section(title: 'Recently played', items: mockAlbums()),
    Section(title: 'Picked for you', items: mockSongs().map((s) => BrowseItem(kind: 'song', id: 'p_${s.videoId}', title: s.title, subtitle: s.artists, thumbnail: s.thumbnail, duration: s.duration)).toList()),
  ],
);