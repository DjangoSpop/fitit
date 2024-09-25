import 'package:flutter/material.dart';

import '../services/DataBaseHelper.dart';
import '../screens/HomePage.dart';


class UserProfilePage extends StatefulWidget {
  final bool isInitialSetup;

  UserProfilePage({this.isInitialSetup = false});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _name = '';
  int _age = 0;
  double _height = 0.0;
  double _weight = 0.0;
  String _gender = '';
  String _fitnessGoal = '';
  String _dietaryRestrictions = '';
  String _fitnessLevel = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isInitialSetup) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final userProfile = await _dbHelper.getUserProfile();
    if (userProfile != null) {
      setState(() {
        _name = userProfile['name'] ?? '';
        _age = userProfile['age'] ?? 0;
        _height = userProfile['height'] ?? 0.0;
        _weight = userProfile['weight'] ?? 0.0;
        _gender = userProfile['gender'] ?? '';
        _fitnessGoal = userProfile['fitness_goal'] ?? '';
        _dietaryRestrictions = userProfile['dietary_restrictions'] ?? '';
        _fitnessLevel = userProfile['fitness_level'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Set Up Your Profile' : 'Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _age == 0 ? '' : _age.toString(),
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
                onSaved: (value) => _age = int.parse(value!),
              ),
              TextFormField(
                initialValue: _height == 0.0 ? '' : _height.toString(),
                decoration: InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  return null;
                },
                onSaved: (value) => _height = double.parse(value!),
              ),
              TextFormField(
                initialValue: _weight == 0.0 ? '' : _weight.toString(),
                decoration: InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  return null;
                },
                onSaved: (value) => _weight = double.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _gender.isNotEmpty ? _gender : null,
                decoration: InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _fitnessGoal.isNotEmpty ? _fitnessGoal : null,
                decoration: InputDecoration(labelText: 'Fitness Goal'),
                items: ['Lose Weight', 'Gain Muscle', 'Improve Endurance', 'Maintain Fitness'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _fitnessGoal = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your fitness goal';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _dietaryRestrictions,
                decoration: InputDecoration(labelText: 'Dietary Restrictions'),
                onSaved: (value) => _dietaryRestrictions = value!,
              ),
              DropdownButtonFormField<String>(
                value: _fitnessLevel.isNotEmpty ? _fitnessLevel : null,
                decoration: InputDecoration(labelText: 'Current Fitness Level'),
                items: ['Beginner', 'Intermediate', 'Advanced'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _fitnessLevel = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your current fitness level';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(widget.isInitialSetup ? 'Complete Setup' : 'Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final userProfile = {
        'name': _name,
        'age': _age,
        'height': _height,
        'weight': _weight,
        'gender': _gender,
        'fitness_goal': _fitnessGoal,
        'dietary_restrictions': _dietaryRestrictions,
        'fitness_level': _fitnessLevel,
      };

      final existingProfile = await _dbHelper.getUserProfile();
      if (existingProfile == null) {
        await _dbHelper.insertUserProfile(userProfile);
      } else {
        userProfile['id'] = existingProfile['id'];
        await _dbHelper.updateUserProfile(userProfile);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully')),
      );

      if (widget.isInitialSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }
}