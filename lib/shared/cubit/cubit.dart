// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:to_do_app/modules/archived_tasks.dart';
import 'package:to_do_app/modules/done_tasks.dart';
import 'package:to_do_app/modules/new_tasks.dart';
import 'package:to_do_app/shared/cubit/states.dart';
import 'package:sqflite/sqflite.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;
  var direction;
  List<Widget> screens = const [
    NewTaskScreen(),
    DoneTaskScreen(),
    ArchivedTaskScreen(),
  ];
  List<String> titles = const [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks',
  ];
  Database? database;
  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];

  //داله ال ChangeBottomNav
  void changeIndex(int index) {
    currentIndex = index;
    emit(AppChangeBottomNavState());
  }

  changeDirection(dir) {
    emit(AppChangeDirection());
    return direction = dir;
  }

  //داله ال create
  Future createDatabase() async {
    openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version) async {
        print('Database created');
        database
            .execute(
                'CREATE TABLE tasks(id INTEGER PRIMARY KEY,title TEXT,place TEXT,date TEXT,time TEXT,states TEXT )')
            .then((value) {
          print('Table Created');
        }).catchError((error) {
          print('Error When Creating Table ${error.toString()}');
        });
      },
      onOpen: (database) {
        //هنوقف ال get دلوقتي
        getDataFromDatabase(database);
        print('Database Opened');
      },
      //  هنعمل .then بدل ال await و ال async
      //  وبعدين هنعمل emit لل AppCreateDatabaseState
    ).then((value) {
      database = value;
      emit(AppCreateDatabaseState());
    });
  }

  //داله ال update
  void updateData({
    required String states,
    required int id,
  }) async {
    await database?.rawUpdate(
      'UPDATE tasks SET states = ? WHERE id = ?',
      [states, id],
    ).then((value) {
      emit(AppUpdateDatabaseState());
      getDataFromDatabase(database);
    });
  }

  //داله ال delete
  void deleteData({
    required int id,
  }) async {
    await database
        ?.rawUpdate('DELETE FROM  tasks  WHERE id = ?', [id]).then((value) {
      emit(AppDeleteDatabaseState());
      getDataFromDatabase(database);
    });
  }

  //داله ال insert
  Future insertToDatabase({
    required String title,
    required String place,
    required String time,
    required String date,
  }) async {
    await database!.transaction((txn) async {
      txn
          .rawInsert(
              'INSERT INTO tasks(title,place,date,time,states ) VALUES ("$title","$place","$date","$time","new")')
          .then((value) {
        print('$value Inserted Successfully');
        emit(AppInsertDatabaseState());

        //جيبت دي هنا عشان بعد م يعمل insert  يعمل get ل data اللي عمل لها insert
        getDataFromDatabase(database);
      }).catchError((error) {
        print('Error When Inserting New Record ${error.toString()}');
      });
    });
  }

  //داله ال getData
  void getDataFromDatabase(database) {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];

    //جيبت ال then. هناا بدل مل افضل اخدها كوبي بيست كل شويه ف م الافضل تكون
    database!.rawQuery('SELECT * FROM tasks').then((value) {
      emit(AppGetDatabaseState());
      value.forEach((element) {
        if (element['states'] == 'new') {
          newTasks.add(element);
        } else if (element['states'] == 'done') {
          doneTasks.add(element);
        } else {
          archivedTasks.add(element);
        }
      });
    });
  }

  bool isBottomSheetShown = false;
  IconData fabIcon = Icons.edit;

  //داله ال changeBottomSheet
  void changeBottomSheetShown({
    required bool isShown,
    required IconData icon,
  }) {
    isBottomSheetShown = isShown;
    fabIcon = icon;
    emit(AppChangeBottomSheetState());
  }
}
