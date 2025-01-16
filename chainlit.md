## Welcome to Sense!

Sense is your database assistant - your version of Sense should have come connected to a database. You can now use the chat interface to interact with your database as if it were a person, in natural language! For example:

1. **What datasets do you have?** 
   This will print out a data catalogue, complete with the descriptions of every single data field.

2. **Given the data schema, what are some possible queries I can make?**
   This is an exploratory query that helps brainstorm some potential questions you could ask.

Try experimenting with your unique policy and operational queries.

### Tips:

1. **Sense works best when complicated queries are reduced into step-by-step simple queries.**
   If you have a complicated query with over 5 different operations, we advise reframing them into a series of smaller queries.

2. **You can ask Sense for its underlying assumptions or to explain the calculation methodology.** Feel free to ask Sense how it landed on a particular way of performing a calculation.

3. **Always check the SQL output.** Even if you cannot read code, you can always make sure the correct datafields are used by Sense - if incorrect, tell Sense where it went wrong!

4. **When there are errors, you should investigate the underlying data quality.** You should use sense to figure out quirks in your data that will produce computation errors (e.g. are there some columns where the value is "0" such that dividing by that column results in an error, or are there columns where formatting is inconsistent?)

Check out [our tutorials here](https://www.youtube.com/watch?v=FvO5Dy94E44&list=PLYtMyMEvarrktLh2ETxkn_Bz77RhqGLRB), where we bring you through specific prompts optimised for Sense.