// Assignment 04: MongoDB Bookstore
// Run with: mongosh mongodb_assignment.js

db = db.getSiblingDB("bookstore");

db.books.drop();

db.books.insertMany([
  { title: "Clean Code", author: "Robert C. Martin", category: "Programming", price: 35, in_stock: true, published_year: 2008, rating: 4.8 },
  { title: "The Pragmatic Programmer", author: "Andrew Hunt", category: "Programming", price: 42, in_stock: true, published_year: 1999, rating: 4.7 },
  { title: "Design Patterns", author: "Erich Gamma", category: "Programming", price: 55, in_stock: true, published_year: 1994, rating: 4.6 },
  { title: "Refactoring", author: "Martin Fowler", category: "Programming", price: 48, in_stock: false, published_year: 2018, rating: 4.5 },
  { title: "Effective Java", author: "Joshua Bloch", category: "Programming", price: 50, in_stock: true, published_year: 2018, rating: 4.8 },
  { title: "JavaScript: The Good Parts", author: "Douglas Crockford", category: "Programming", price: 28, in_stock: true, published_year: 2008, rating: 4.2 },
  { title: "You Don't Know JS", author: "Kyle Simpson", category: "Programming", price: 32, in_stock: true, published_year: 2015, rating: 4.4 },
  { title: "Database Internals", author: "Alex Petrov", category: "Databases", price: 60, in_stock: true, published_year: 2019, rating: 4.7 },
  { title: "SQL Performance Explained", author: "Markus Winand", category: "Databases", price: 44, in_stock: false, published_year: 2012, rating: 4.6 },
  { title: "MongoDB: The Definitive Guide", author: "Shannon Bradshaw", category: "Databases", price: 47, in_stock: true, published_year: 2019, rating: 4.4 },
  { title: "Redis in Action", author: "Josiah Carlson", category: "Databases", price: 39, in_stock: true, published_year: 2013, rating: 4.3 },
  { title: "Seven Databases in Seven Weeks", author: "Eric Redmond", category: "Databases", price: 41, in_stock: true, published_year: 2018, rating: 4.2 },
  { title: "Deep Learning", author: "Ian Goodfellow", category: "AI", price: 72, in_stock: true, published_year: 2016, rating: 4.5 },
  { title: "Hands-On Machine Learning", author: "Aurelien Geron", category: "AI", price: 58, in_stock: true, published_year: 2022, rating: 4.8 },
  { title: "Pattern Recognition and Machine Learning", author: "Christopher Bishop", category: "AI", price: 65, in_stock: false, published_year: 2006, rating: 4.6 },
  { title: "Artificial Intelligence: A Modern Approach", author: "Stuart Russell", category: "AI", price: 75, in_stock: true, published_year: 2020, rating: 4.7 },
  { title: "The Hundred-Page Machine Learning Book", author: "Andriy Burkov", category: "AI", price: 36, in_stock: true, published_year: 2019, rating: 4.6 },
  { title: "Thinking, Fast and Slow", author: "Daniel Kahneman", category: "Psychology", price: 22, in_stock: true, published_year: 2011, rating: 4.5 },
  { title: "Atomic Habits", author: "James Clear", category: "Psychology", price: 24, in_stock: true, published_year: 2018, rating: 4.8 },
  { title: "Influence", author: "Robert Cialdini", category: "Psychology", price: 27, in_stock: false, published_year: 2006, rating: 4.4 },
  { title: "Drive", author: "Daniel Pink", category: "Psychology", price: 21, in_stock: true, published_year: 2009, rating: 4.2 },
  { title: "Mindset", author: "Carol Dweck", category: "Psychology", price: 20, in_stock: true, published_year: 2006, rating: 4.3 },
  { title: "Sapiens", author: "Yuval Noah Harari", category: "History", price: 26, in_stock: true, published_year: 2014, rating: 4.7 },
  { title: "Homo Deus", author: "Yuval Noah Harari", category: "History", price: 29, in_stock: true, published_year: 2016, rating: 4.4 },
  { title: "Guns, Germs, and Steel", author: "Jared Diamond", category: "History", price: 30, in_stock: false, published_year: 1997, rating: 4.1 },
  { title: "The Silk Roads", author: "Peter Frankopan", category: "History", price: 34, in_stock: true, published_year: 2015, rating: 4.3 },
  { title: "The Innovators", author: "Walter Isaacson", category: "History", price: 33, in_stock: true, published_year: 2014, rating: 4.2 },
  { title: "Good Strategy Bad Strategy", author: "Richard Rumelt", category: "Business", price: 31, in_stock: true, published_year: 2011, rating: 4.6 },
  { title: "The Lean Startup", author: "Eric Ries", category: "Business", price: 25, in_stock: true, published_year: 2011, rating: 4.3 },
  { title: "Zero to One", author: "Peter Thiel", category: "Business", price: 23, in_stock: false, published_year: 2014, rating: 4.2 }
]);

print("Initial book count:");
printjson(db.books.countDocuments());

// Task 2: Create - add at least 5 books.
db.books.insertMany([
  { title: "System Design Interview", author: "Alex Xu", category: "Programming", price: 45, in_stock: true, published_year: 2020, rating: 4.6 },
  { title: "Data-Intensive Applications", author: "Martin Kleppmann", category: "Databases", price: 54, in_stock: true, published_year: 2017, rating: 4.9 },
  { title: "Life 3.0", author: "Max Tegmark", category: "AI", price: 30, in_stock: true, published_year: 2017, rating: 4.2 },
  { title: "The Psychology of Money", author: "Morgan Housel", category: "Business", price: 19, in_stock: true, published_year: 2020, rating: 4.7 },
  { title: "A Short History of Nearly Everything", author: "Bill Bryson", category: "History", price: 28, in_stock: true, published_year: 2003, rating: 4.5 }
]);

// Task 2: Read queries.
print("Programming books:");
printjson(db.books.find({ category: "Programming" }).toArray());

print("Books published after 2015:");
printjson(db.books.find({ published_year: { $gt: 2015 } }).toArray());

print("Books priced above 40:");
printjson(db.books.find({ price: { $gt: 40 } }).toArray());

print("Books in stock:");
printjson(db.books.find({ in_stock: true }).toArray());

print("Books by Martin Fowler:");
printjson(db.books.find({ author: "Martin Fowler" }).toArray());

print("Books with rating greater than 4.5:");
printjson(db.books.find({ rating: { $gt: 4.5 } }).toArray());

// Task 2: Update operations.
db.books.updateOne({ title: "Clean Code" }, { $set: { price: 37 } });
db.books.updateOne({ title: "Refactoring" }, { $set: { in_stock: true } });
db.books.updateOne({ title: "Redis in Action" }, { $inc: { rating: 0.2 } });

print("Updated books:");
printjson(db.books.find({ title: { $in: ["Clean Code", "Refactoring", "Redis in Action"] } }).toArray());

// Task 2: Delete at least 2 books.
db.books.deleteMany({ title: { $in: ["Zero to One", "Guns, Germs, and Steel"] } });

print("Book count after deletes:");
printjson(db.books.countDocuments());

// Task 3: Aggregations.
print("Average book price per category:");
printjson(db.books.aggregate([
  { $group: { _id: "$category", average_price: { $avg: "$price" } } },
  { $sort: { average_price: -1 } }
]).toArray());

print("Number of books per category:");
printjson(db.books.aggregate([
  { $group: { _id: "$category", book_count: { $sum: 1 } } },
  { $sort: { book_count: -1 } }
]).toArray());

print("Average rating per category:");
printjson(db.books.aggregate([
  { $group: { _id: "$category", average_rating: { $avg: "$rating" } } },
  { $sort: { average_rating: -1 } }
]).toArray());

print("Top 5 most expensive books:");
printjson(db.books.aggregate([
  { $sort: { price: -1 } },
  { $limit: 5 },
  { $project: { _id: 0, title: 1, author: 1, category: 1, price: 1 } }
]).toArray());

// Task 4: Query optimization before index.
print("Explain before index:");
printjson(db.books.find({
  category: "Programming",
  published_year: { $gte: 2020 }
}).explain("executionStats"));

db.books.createIndex({ category: 1, published_year: 1 });

print("Explain after compound index:");
printjson(db.books.find({
  category: "Programming",
  published_year: { $gte: 2020 }
}).explain("executionStats"));

print("Indexes:");
printjson(db.books.getIndexes());
