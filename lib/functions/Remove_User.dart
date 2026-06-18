import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management_system/services/registration_service.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class RemoveUserPage extends StatefulWidget {
  const RemoveUserPage({super.key});

  @override
  State<RemoveUserPage> createState() => _RemoveUserPageState();
}

class _RemoveUserPageState extends State<RemoveUserPage> {
  String? _selectedUserEmail;
  List<Map<String, String>> _users = [];
  bool _isLoading = true;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentEmail =
          FirebaseAuth.instance.currentUser?.email?.toLowerCase();
      final snapshot =
          await FirebaseFirestore.instance.collection('registered_users').get();

      final users = snapshot.docs
          .where((doc) => RegistrationService.isRegistered(doc))
          .where((doc) => doc.id.toLowerCase() != currentEmail)
          .map((doc) {
        final data = doc.data();
        final email = (data['email'] as String?) ?? doc.id;
        return {
          'id': doc.id,
          'name': email,
        };
      }).toList();

      users.sort(
        (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
              (b['name'] ?? '').toLowerCase(),
            ),
      );

      if (!mounted) return;

      setState(() {
        _users = users;
        if (_selectedUserEmail != null &&
            !_users.any((user) => user['id'] == _selectedUserEmail)) {
          _selectedUserEmail = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load users. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Success', style: TextStyle(color: Colors.green)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String email) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2E2E2E),
            title: const Text(
              'Confirm Removal',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to remove access for "$email"?\n\n'
              'They will be logged out immediately and will need a new invite to rejoin.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removeSelectedUser() async {
    if (_selectedUserEmail == null) {
      _showErrorDialog('Please select a user to remove.');
      return;
    }

    final selectedUser = _users.firstWhere(
      (user) => user['id'] == _selectedUserEmail,
    );
    final email = selectedUser['name'] ?? _selectedUserEmail!;

    final confirmed = await _showConfirmationDialog(email);
    if (!confirmed) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorDialog('Authentication error. Please sign in again.');
        return;
      }

      await RegistrationService.removeRegisteredUser(
        email: _selectedUserEmail!,
        removedBy: currentUser.email ?? currentUser.displayName ?? 'Unknown User',
        displayEmail: email,
      );

      setState(() {
        _selectedUserEmail = null;
      });

      await _fetchUsers();
      _showSuccessDialog('Successfully removed access for "$email".');
    } catch (e) {
      _showErrorDialog('Error removing user. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: SimpleAppBar(
        title: 'REMOVE USER',
        onBack: () => Navigator.pop(context),
        onProfile: () {},
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.1),
            Text(
              'CHOOSE USER',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.075,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              'Select a registered user to revoke their access.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.035,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: width * 0.05),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_users.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No other registered users found.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width * 0.04,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              UserDropdown(
                value: _selectedUserEmail,
                items: _users,
                width: width,
                onChanged: (value) {
                  setState(() {
                    _selectedUserEmail = value;
                  });
                },
              ),
            const Spacer(),
            if (!_isLoading && _users.isNotEmpty)
              Center(
                child: SizedBox(
                  width: width * 0.35,
                  height: width * 0.125,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: _isRemoving ? null : _removeSelectedUser,
                    child: _isRemoving
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            'REMOVE',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.05,
                            ),
                          ),
                  ),
                ),
              ),
            SizedBox(height: height * 0.08),
          ],
        ),
      ),
    );
  }
}

class UserDropdown extends StatefulWidget {
  final String? value;
  final List<Map<String, String>> items;
  final Function(String?) onChanged;
  final double width;

  const UserDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  State<UserDropdown> createState() => _UserDropdownState();
}

class _UserDropdownState extends State<UserDropdown> {
  bool _isOpen = false;
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.value == null
        ? 'Select'
        : widget.items
            .firstWhere(
              (item) => item['id'] == widget.value,
              orElse: () => {'name': 'Select'},
            )['name'];

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedLabel ?? 'Select',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: widget.width * 0.045,
                    color: widget.value != null ? Colors.white : Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry.remove();
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height),
          child: Material(
            elevation: 4,
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 230),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return ListTile(
                    title: Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: widget.width * 0.045,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      widget.onChanged(item['id']);
                      _closeDropdown();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isOpen) {
      _overlayEntry.remove();
    }
    super.dispose();
  }
}
