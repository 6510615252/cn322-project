import 'package:flutter/material.dart';
import 'package:outstragram/services/storage_service.dart';
import 'screens/feed.dart';
import 'screens/ProfilePage.dart';
import 'screens/Search_Page.dart';
import 'screens/new_post_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:outstragram/widgets/widget_tree.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()),
      ],
      child: const MyApp(),
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Navbar Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF6F1DE),
        primarySwatch: Colors.blue,
      ),
      home: const WidgetTree(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Feed(),
    NewPostPage(),
    SearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(

        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF8AB2A6),
        selectedItemColor: Colors.white, // สีไอคอนและข้อความที่ถูกเลือก
        unselectedItemColor: const Color.fromARGB(255, 102, 100, 100),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'New Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
