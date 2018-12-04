# Operator

An iOS client app for MikroTik routers that presents their network interface statistics in a graphical way.

This is an test exercise to apply for a position in MikroTik.

### Running the app

Open `Operator.xcworkspace` (the white icon), select "Operator" and the desired device in top left corner of Xcode, press the "Play" button and Everything Should Just Work™️.

Pods are checked in the repository for easier deployment and should not be manually installed.

### Tests

There is a single unit test for `Interpreter` framework that tests if sentences can be encoded and decoded. Would be nice to test `Client` by making a fake server, but I ran out time.

### Challenges

The most frustrating thing was to choose the right socket library. I ended up choosing `BlueSocket`, because it's actively maintained, backed by IBM and has more than 800 stars in GitHub. Pretty much everything else is either outdated or has very few users.

### Lastly

It was really fun to work on this exercise since it had a good balance of networking, custom decoding and encoding and user interface related work.

Priekā!
