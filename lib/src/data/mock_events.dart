import '../models/event.dart';

final mockEvents = <Event>[
  Event(
    id: '1',
    title: 'Balloon Festival',
    location: 'Singha Park, Chiang Rai',
    shortLocation: 'Chiang Rai',
    date: DateTime(DateTime.now().year, 8, 31),
    priceBaht: 400,
    imageUrl: 'https://picsum.photos/seed/balloon/1200/800?q=80&w=1080&auto=format&fit=crop',
    description:
        'Experience colorful hot-air balloons over fields and flowers with food markets and Thai cultural shows.',
    gallery: [
      'https://picsum.photos/seed/balloon2/1200/800?q=80&w=1080&auto=format&fit=crop',
      'https://picsum.photos/seed/balloon3/1200/800?q=80&w=1080&auto=format&fit=crop',
      'https://picsum.photos/seed/balloon/1200/800?q=80&w=1080&auto=format&fit=crop',
    ],
  ),
  Event(
    id: '2',
    title: 'Flower Festival',
    location: 'Chiang Rai',
    shortLocation: 'Chiang Rai',
    date: DateTime(DateTime.now().year, 7, 7),
    priceBaht: 250,
    imageUrl: 'https://picsum.photos/seed/flowers/1200/800?q=80&w=1080&auto=format&fit=crop',
    description: 'Seasonal blossoms, light tunnel, and local food stalls.',
    gallery: [],
  ),
  Event(
    id: '3',
    title: 'Zipline Adventure',
    location: 'Chiang Rai',
    shortLocation: 'Chiang Rai',
    date: DateTime(DateTime.now().year, 8, 9),
    priceBaht: 200,
    imageUrl: 'https://picsum.photos/seed/zipline/1200/800?q=80&w=1080&auto=format&fit=crop',
    description: 'High-adrenaline zipline through lush forests.',
    gallery: [],
  ),
  Event(
    id: '4',
    title: 'ATV Tour',
    location: 'Chiang Rai',
    shortLocation: 'Chiang Rai',
    date: DateTime(DateTime.now().year, 8, 15),
    priceBaht: 500,
    imageUrl: 'https://picsum.photos/seed/atv/1200/800?q=80&w=1080&auto=format&fit=crop',
    description: 'Off-road adventure with scenic viewpoints.',
    gallery: [],
  ),
];
