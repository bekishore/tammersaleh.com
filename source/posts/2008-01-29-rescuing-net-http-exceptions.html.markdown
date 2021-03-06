---
date: 2008-01-29 12:00 PDT
title: Rescuing Net::HTTP exceptions
---

Working with [`Net::HTTP`](http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html) can be a pain.  It's got about 40 different ways to do any one task, and about 50 exceptions it can throw.

Just for the love of google, here's what I've got for the "right way" of catching any exception that Net::HTTP can throw at you:

~~~ ruby
begin
  response = Net::HTTP.post_form(...) # or any Net::HTTP call
rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  ...
end
~~~

Why not just `rescue Exception => e`?  That's a bad habit to get into, as it hides any problems in your actual code (like SyntaxErrors, whiny nils, etc).  Of course, this would all be much easier if the possible errors had a common ancestor.

The issues I've been seeing in dealing with Net::HTTP have made me wonder if it wouldn't be worth it to write a new HTTP client library.  One that was easier to mock out in tests, and didn't have all these ugly little facets.

Comment below if you know of more exceptions it should catch, or of an easier way to get this done.
