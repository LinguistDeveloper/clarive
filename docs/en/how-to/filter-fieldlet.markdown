---
title: Filters in fieldlets
index: 5000
icon: wrench
---

We have this kind of filters in the following fieldlets:

- [Topic Selector](rules/palette/fieldlets/topic-selector)
- [Release Combo](rules/palette/fieldlets/release-combo)
- [CI List](rules/palette/fieldlets/ci-list)
- [CI Grid](rules/palette/fieldlets/ci-grid)
- [CI Combo](rules/palette/fieldlets/ci-combo)

In this fieldlets, we have to configure three fields:

- `Filter field` - This field is a combo with every fieldlets that are in the form. It is important
	to save the form before use this combo, because the fieldlets unsaved will not
	appear in the combo.
	In this field, we are selecting the fieldlets where we pick up the values of the filter.
- `Filter data` - In this field, we have to introduce the key of our filter.
- `Filter type` - We have to select if we want a filter with or-logic or with and-logic.

### Examples

We want to filter topics by users. We have two fieldlets, the first one is a user combo with id 'users',
and the second one is topic selector with id 'topics'.
The fieldlets 'users' has to be in the form above topics fieldlet.
In the topics fieldlets, we would select:

- Filter field - users.
- Filter data - owner.
- Filter type - OR.

With this, we are creating a filter like:

		{'owner':$in['user-1, user-2..']}

Now, we want to filter a ci combo using a pill. The first step, is creating a pill with the id 'pills' and the following setting:

- Option settings - user;project
- DefaultValue - user

Then, we create a ci combo with id 'ci_combo'. For this fieldlet we have to select:

- Filter field - pills.
- Filter data - collection.
- Filter type - OR.

Now, we are going to create a more complex filter. We create two fieldlets, one ci combo  with id 'ci_combo' with the following setting:

- Roles - All
- CI Class - project

And now, create a topic selector with id 'topic_selector' and:

- Advanced Filter JSON - {'name_status': 'New'}
- Filter field - ci_combo
- Filter data - system

With this filter, after selecting a project, we obtain all the topics that has the project in status 'New'.

