---
date: 2007-08-15 12:00 PDT
title: It's the little things...
---

Sometimes it's the little things that really make coding fun.

We used to use a common pattern that helped out with our view code.  By adding the `link_to_xxx` 
helpers, we could make our applications more consistent and maintainable:

~~~ ruby
def link_to_candidate(candidate, msg = nil)
  link_to(msg || h(candidate.name), candidate_path(candidate))
end

def link_to_issue(issue, msg = nil)
  link_to(msg || h(issue.title), issue_path(issue))
end

def link_to_intern(intern, msg = nil)
  link_to(msg || h(intern.name), intern_path(intern.candidate, intern))
end

#...and on...
~~~

But this grows out of hand pretty quickly -- In one application we have over 30 of those puppies.
Well, we figured out that by being a little clever, we could really clean this up...

~~~ ruby
def link(item, msg = nil)
  case item
  when Candidate: link_to(msg || h(item.name),  candidate_path(item))
  when Issue:     link_to(msg || h(item.title), issue_path(item))
  when Intern:    link_to(msg || h(item.name),  intern_path(item.candidate, item))
  #...
  else raise ArgumentError, "Unrecognized item given to link: #{item}"
  end
end
~~~

Well, that's much better.  It only grows one line for each model instead of four, 
and it's easier to call in the views.  

~~~
Candidates!
<% @candidates.each do |candidate| %>
  <%= link candidate %>
<% end %>
~~~

But it still smells a little fishy.  I don't think anyone here at Thoughtbot likes seeing a case statement.  
Let's get just a *little* more clever...

#### Abandon hope, all ye who enter here

~~~ ruby
def link(item, msg = nil)
  msg ||= item.send([:name, :title, :id].detect {|n| item.respond_to? n})
  method = "#{item.class.name.underscore}_path"
  link_to(msg, self.send(method, item))
end
~~~

If you're still with me -- this version of `link()` figures out what attribute to call on the give model and
generates the `xxx_path` method.  It's very concise, and won't grow with the size of your code base, 
but hot-damn is it a doozy to decipher.  But a larger issue is that we lost our ability
to handle nested resources (like `intern_path(intern.candidate, intern)`).  

Now, we definitely went with the case-statement version up there, but just as an exercise...  

Let's just say we required all nested models to provide a `parents` attribute, which returned the list 
of parent models.  We could then clean up our `link()` method like so:

~~~ ruby
def link(item, msg = nil)
  msg ||= item.send([:name, :title, :id].detect {|n| item.respond_to? n})
  method = "#{item.class.name.underscore}_path"
  parents = item.parents rescue []
  link_to(msg, self.send(method, *parents, item))
end
~~~

I wonder what else could be simplified if the models could tell you what other 
models proceed them in the resource chain.
