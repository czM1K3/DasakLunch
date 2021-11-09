import 'package:dasaklunch/models/lunch.dart';
import 'package:dasaklunch/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'auth_required_state.dart';

class LunchesList extends StatefulWidget {
  const LunchesList({Key? key}) : super(key: key);

  @override
  _LunchesListState createState() => _LunchesListState();
}

class _LunchesListState extends AuthRequiredState<LunchesList> {
  static const _pageSize = 20;

  final PagingController<int, Lunch> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController
        .addPageRequestListener((pageNumber) => _fetchPage(pageNumber));
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int alreadyFetched) async {
    final response = await supabase
        .from("lunches")
        .select()
        .order("name", ascending: true)
        .range(alreadyFetched, alreadyFetched + _pageSize - 1)
        .execute();
    final error = response.error;
    if (error != null && response.status != 406) {
      context.showErrorSnackBar(message: error.message);
      return;
    }
    final data = response.data;
    if (data != null) {
      final newLunches = List<Lunch>.from(data.map((lunch) {
        return Lunch(id: lunch["id"], name: lunch["name"]);
      }));
      final isLastPage = newLunches.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newLunches);
      } else {
        final nextPageKey = alreadyFetched + newLunches.length;
        _pagingController.appendPage(newLunches, nextPageKey);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<Lunch>(
        itemBuilder: (context, item, index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, "/lunch", arguments: {
                "lunch": item,
              });
            },
            child: Text(item.name),
          ),
        ),
      ),
    );
  }
}
