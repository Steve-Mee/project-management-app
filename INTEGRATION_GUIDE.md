// INTEGRATION GUIDE - Update your main.dart with this code

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/repository/hive_initializer.dart';
// Import your other pages/widgets here

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for data persistence
  await HiveInitializer.initialize();
  
  runApp(
    ProviderScope(
      // Wrap your app with ProjectsInitializer to load projects from Hive
      child: ProjectsInitializer(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      // Add your routes here
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: const Center(child: Text('Your project management content here')),
    );
  }
}

// ============================================================================
// WHAT CHANGED:
// ============================================================================
// 
// 1. Added 'await HiveInitializer.initialize()' to main()
//    - Initializes Hive database for persistence
// 
// 2. Wrapped app with ProviderScope (required for Riverpod)
//    - Enables all provider functionality
// 
// 3. Wrapped ProviderScope child with ProjectsInitializer
//    - Loads projects from Hive on app startup
//    - Shows loading screen while initializing
//    - Automatically calls initialize() on the projects provider
// 
// ============================================================================
// NEXT STEPS:
// ============================================================================
// 
// 1. Update your main.dart with the above code
// 
// 2. In any widget where you want to use projects, use ConsumerWidget:
//    
//    class MyProjectList extends ConsumerWidget {
//      @override
//      Widget build(BuildContext context, WidgetRef ref) {
//        final projectsAsync = ref.watch(projectsProvider);
//        return projectsAsync.when(
//          data: (projects) => ListView(...),
//          loading: () => CircularProgressIndicator(),
//          error: (e, st) => Text('Error: $e'),
//        );
//      }
//    }
// 
// 3. To add/update/delete projects:
//    
//    final notifier = ref.read(projectsProvider.notifier);
//    await notifier.addProject(myProject);      // Add
//    await notifier.updateProgress(id, 0.75);   // Update progress
//    await notifier.updateTasks(id, newTasks);  // Update tasks
//    await notifier.deleteProject(id);          // Delete
// 
// 4. All changes are automatically:
//    - Saved to Hive (persistent storage)
//    - Reflected in all watching widgets (reactive updates)
//
// ============================================================================
