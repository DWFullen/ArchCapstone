# HTML Cheat Sheet for Blazor Web Pages

## Basic HTML Structure
<!-- Defines the basic structure of an HTML document with a title, heading, and paragraph. -->
```html
<!DOCTYPE html>
<html>
<head>
    <title>Page Title</title>
</head>
<body>
    <h1>This is a Heading</h1>
    <p>This is a paragraph.</p>
</body>
</html>
```

## Common HTML Elements

### Headings
<!-- Used to create headings of different levels, from largest (h1) to smallest (h6). -->
```html
<h1>Heading 1</h1>
<h2>Heading 2</h2>
<h3>Heading 3</h3>
<h4>Heading 4</h4>
<h5>Heading 5</h5>
<h6>Heading 6</h6>
```

### Paragraphs
<!-- Represents a block of text as a paragraph. -->
```html
<p>
    This is a paragraph that spans multiple lines.<br>
    You can use the &lt;br&gt; tag to insert line breaks.<br>
    Each line will appear on a new line in the browser.
</p>
```

### Links
<!-- Creates a hyperlink to another webpage or resource. -->
```html
<a href="https://example.com">Visit Example</a>
```

### Images
<!-- Displays an image with a description for accessibility. -->
```html
<img src="image.jpg" alt="Description of image">
```

### Lists
#### Ordered List
<!-- Creates a numbered list of items. -->
```html
<ol>
    <li>Item 1</li>
    <li>Item 2</li>
    <li>Item 3</li>
</ol>
```
#### Unordered List
<!-- Creates a bulleted list of items. -->
```html
<ul>
    <li>Item 1</li>
    <li>Item 2</li>
    <li>Item 3</li>
</ul>
```

### Tables
<!-- Displays tabular data with headers and rows. -->
```html
<table>
    <tr>
        <th>Header 1</th>
        <th>Header 2</th>
    </tr>
    <tr>
        <td>Data 1</td>
        <td>Data 2</td>
    </tr>
</table>
```

### Forms
<!-- Creates a form for user input with a text field and submit button. -->
```html
<form>
    <label for="name">Name:</label>
    <input type="text" id="name" name="name">
    <input type="submit" value="Submit">
</form>
```

## HTML in Blazor

### Data Binding
<!-- Binds the input field to a property in the Blazor component. Data binding in Blazor allows you to establish a two-way connection between the UI and the underlying data model. When the user modifies the value in the input field, the corresponding property in the Blazor component is automatically updated. Similarly, changes to the property in the component are reflected in the UI. This ensures synchronization between the UI and the data model, making it easier to manage state and user interactions. -->
```html
<input @bind="BoundProperty" />
```
<!-- Example Use Case: Imagine you have a form where users can input their name. By binding the input field to a property called `UserName`, any changes made by the user will automatically update the `UserName` property in the Blazor component. Similarly, if the `UserName` property is updated programmatically, the input field will reflect the new value. -->
<!-- For more information, visit the official Blazor documentation on Data Binding: https://learn.microsoft.com/en-us/aspnet/core/blazor/components/data-binding -->

### Event Handling
<!-- Triggers a method in the Blazor component when the button is clicked. -->
```html
<button @onclick="HandleClick">Click Me</button>
```

### Conditional Rendering
<!-- Renders content based on a condition. -->
```html
@if (IsVisible)
{
    <p>This is conditionally rendered.</p>
}
```

### Loops
<!-- Iterates over a collection and renders each item. -->
```html
@foreach (var item in Items)
{
    <p>@item</p>
}
```

### Components
<!-- Embeds a Blazor component with parameters. -->
```html
<MyComponent Parameter="Value" />
```

## CSS Integration

### Inline Styles
<!-- Applies styles directly to an HTML element. -->
```html
<p style="color: red;">This is red text.</p>
```

### External Stylesheets
<!-- Links an external CSS file for styling. -->
```html
<link rel="stylesheet" href="styles.css">
```

### Classes
<!-- Applies a CSS class to an HTML element for styling. -->
```html
<p class="my-class">This is styled text.</p>
```

## Accessibility

### Alt Text for Images
<!-- Provides a text description for images to improve accessibility. -->
```html
<img src="image.jpg" alt="Description of image">
```

### Labels for Forms
<!-- Associates a label with a form input for better accessibility. -->
```html
<label for="name">Name:</label>
<input type="text" id="name" name="name">
```

### Semantic HTML
<!-- Defines navigation links using semantic HTML elements. -->
```html
<nav>
    <ul>
        <li><a href="/home">Home</a></li>
        <li><a href="/about">About</a></li>
    </ul>
</nav>
```
