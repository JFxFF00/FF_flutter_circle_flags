This just removed flags that are not used by the `flutter_country_selector` & `phone_form_field` package as they only use a subset of the flags and flutter does not have assets tree shaking as of yet

Execute from root with

  - dart packages/flag_tree_shaker/bin/flag_tree_shaker.dart 