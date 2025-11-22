import 'package:flutter/material.dart';

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

enum Task { Pending, Accepted, Completed, Rejected }

class _TasksState extends State<Tasks> {
  Task _selectedTask = Task.Pending;

  @override
  Widget build(BuildContext context) {
    // Calculate the width of the screen to make the tab responsive,
    // or define a fixed height for the container.
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        height: 50, // Fixed height for the toggle bar
        decoration: BoxDecoration(
          color: Colors.blue[50], // Background color of the track
          borderRadius: BorderRadius.circular(25.0), // Rounded corners
        ),
        child: Stack(
          children: [
            // 1. The Animated Slider (The "Pill")
            AnimatedAlign(
              alignment: Alignment(
                // Logic to map the Enum index (0 to 3) to Alignment (-1.0 to 1.0)
                (_selectedTask.index / (Task.values.length - 1)) * 2 - 1,
                0,
              ),
              duration: const Duration(milliseconds: 250), // Animation speed
              curve: Curves.easeInOut, // Smooth sliding effect
              child: FractionallySizedBox(
                widthFactor: 1 / Task.values.length, // Take up 1/4th of width
                heightFactor: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(4.0), // Padding for the pill
                  decoration: BoxDecoration(
                    color: Colors.blue[700], // Active color
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 2. The Clickable Text Labels
            Row(
              children: Task.values.map((task) {
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        _selectedTask = task;
                      });
                    },
                    child: Center(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          // Change text color based on selection for contrast
                          color: _selectedTask == task
                              ? Colors.white
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
