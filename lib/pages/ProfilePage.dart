import 'package:flutter/material.dart';
import 'package:outstragram/auth.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Username'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
        await Auth().signOut();
            }
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                      'https://th.bing.com/th/id/OIP.fbDzVLOpIomCfhKskpEAlwHaHa?rs=1&pid=ImgDetMain'),
                ),
                Column(
                  children: [
                    Text('100',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Posts')
                  ],
                ),
                Column(
                  children: [
                    Text('200K',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Followers')
                  ],
                ),
                Column(
                  children: [
                    Text('150',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Following')
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10), // เพิ่ม margin bottom
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Bio goes here...'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.grey[300],
                  child: Image.network(
                      'https://th.bing.com/th/id/OIP.Tbiqhko7HQvEi3VuTYh63AHaHa?rs=1&pid=ImgDetMain',
                      fit: BoxFit.cover),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
