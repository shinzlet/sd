# sd - Smart Directory

This readme will be updated as soon as I've got this program somewhat usable, but for now I'll throw down a quick explanation of what it is.

When I work in linux, my workflow is usually a little something like this:

(in a terminal)
mkdir ~/src/new_project
cd ~/src/new_project
nvim source_code.cr

(then, in a new terminal next to that)
cd ~/src/new_project
nvim readme.md

and then I do that a couple more times, opening terminals to write makefiles,
using other terminals to actually build and execute the code, yadda yadda. There's
one thing here that's a *huge* pain, which is the cd step. When I get working on a
project, the odds that I open a terminal with the intentions to navigate to a
different directory than that of the project are slim to none. So, I fixed it by writing
a fish script. I set things up so I could just type "project here", and all new terminals
would open in that directory. It saved me a huge amount of time, and eventually I realized
that there are a lot of things that annoy me about cd.

So, here's what I want sd to do:
- Toggle a lock mode, where all new terminals will open in a specified directory.
- Create folder aliases, and navigate to those without having to type the full path.
- Anything else reasonable that gets pitched to me.

I'm hoping to have an mvp of this done in a couple days. Tag along, why don't 'ya?!
