import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class Movie {
  final String title;
  final String posterPath;

  Movie({required this.title, required this.posterPath});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movies Lister',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // Set the background color here
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  Future<List<Movie>> fetchMovies(String endpoint) async {
    final apiKey = '8cf85336f6e4275b4014b0207e26671d'; // Replace with your actual API key
    final apiBaseUrl = 'https://api.themoviedb.org/3';
    final response = await http.get(Uri.parse('$apiBaseUrl$endpoint?api_key=$apiKey'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<Movie> movies = (data['results'] as List)
          .map((item) => Movie(
                title: item['title'],
                posterPath: item['poster_path'],
              ))
          .toList();
      return movies;
    } else {
      throw Exception('Failed to load movies');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movies Lister',style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(Icons.playlist_add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => WatchListScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            MovieList(title: 'Trending Movies', fetchMovies: fetchMovies, endpoint: '/movie/popular'),
            SizedBox(height: 16),
            MovieList(title: 'Top Rated Movies', fetchMovies: fetchMovies, endpoint: '/movie/top_rated'),
            SizedBox(height: 16),
            MovieList(title: 'Now Playing Movies', fetchMovies: fetchMovies, endpoint: '/movie/now_playing'),
          ],
        ),
      ),
    );
  }
}

class MovieList extends StatelessWidget {
  final String title;
  final Future<List<Movie>> Function(String) fetchMovies;
  final String endpoint;

  MovieList({required this.title, required this.fetchMovies, required this.endpoint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          height: 300,
          child: FutureBuilder(
            future: fetchMovies(endpoint),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<Movie> movies = snapshot.data as List<Movie>;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length * 60, // Triple the length for looping
                  itemBuilder: (context, index) {
                    final movie = movies[index % movies.length];
                    return MovieCard(movie: movie, context:context);
                  },
                );
              }
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class MovieCard extends StatelessWidget {
  final Movie movie;
  final BuildContext context;

  MovieCard({required this.movie, required this.context});

  Future<void> addToWatchList(Movie movie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> watchList = prefs.getStringList('watchList') ?? [];
    
    // Check if the movie is already in the watchlist
    if (!watchList.contains(movie.title)) {
      watchList.add(movie.title);
      prefs.setStringList('watchList', watchList); 
  
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Added to Watchlist'),
          content: Text('${movie.title} has been added to your watchlist!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Already in Watchlist'),
          content: Text('${movie.title} is already in your watchlist!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoverContainer(
            height: 220,
            width: 160,
            child: GestureDetector(
              onTap: () {
                addToWatchList(movie);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            movie.title,
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class HoverContainer extends StatefulWidget {
  final Widget child;
  final double height;
  final double width;

  HoverContainer({required this.child, required this.height, required this.width});

  @override
  _HoverContainerState createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => _mouseEnter(true),
      onExit: (event) => _mouseEnter(false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          border: _isHovered ? Border.all(color: Colors.red, width: 3.0) : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: widget.child,
        ),
      ),
    );
  }

  void _mouseEnter(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }
}

class WatchListScreen extends StatefulWidget {
  @override
  _WatchListScreenState createState() => _WatchListScreenState();
}

class _WatchListScreenState extends State<WatchListScreen> {
  List<String> watchList = [];

  @override
  void initState() {
    super.initState();
    _loadWatchList();
  }

  Future<void> _loadWatchList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      watchList = prefs.getStringList('watchList') ?? [];
    });
  }

  Future<void> _removeFromWatchList(String movieTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      watchList.remove(movieTitle);
    });
    prefs.setStringList('watchList', watchList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.red,
        title: Text('Watch List',style:TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 30)),
      ),
      body: ListView.builder(
        itemCount: watchList.length,
        itemBuilder: (context, index) {
          final movieTitle = watchList[index];
          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  movieTitle,
                  style: TextStyle(
                    color: Colors.white, // Adjust text color as needed
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _removeFromWatchList(movieTitle);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$movieTitle removed from watchlist'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // Reload the watchlist
                    _loadWatchList();
                  },
                  icon: Icon(Icons.delete, color: Colors.red), // Replace with your desired delete icon
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
