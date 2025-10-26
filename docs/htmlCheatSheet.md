# HTML Cheat Sheet

## Document skeleton
```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Page title</title>
    <meta name="description" content="Short description">
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <!-- content -->
    <script src="app.js" defer></script>
</body>
</html>
```

## Common structural elements
- Headings: <h1>…</h1> to <h6>
- Paragraph: <p>Text</p>
- Division/Container: <div class="name">
- Inline grouping: <span>
- Semantic layout: <header>, <nav>, <main>, <section>, <article>, <aside>, <footer>

## Text semantics
- Emphasis & importance: <em>, <strong>
- Inline code: <code>, block code: <pre><code>…
- Quotation: <blockquote> and <q>
- Lists: <ul>, <ol>, <li>
- Definition list: <dl>, <dt>, <dd>

## Links & navigation
```html
<a href="https://example.com" target="_blank" rel="noopener noreferrer">Visit</a>
<a href="#section-id">Internal link</a>
<a href="mailto:me@example.com">Email</a>
```

## Images & responsive images
```html
<img src="img.jpg" alt="description" width="600" loading="lazy">
<picture>
    <source srcset="img.webp" type="image/webp">
    <img src="img.jpg" alt="desc">
</picture>
```
- Use meaningful alt text. Use `srcset` + `sizes` for responsive images.

## Media
```html
<audio controls src="audio.mp3"></audio>
<video controls width="640">
    <source src="video.mp4" type="video/mp4">
    Your browser does not support video.
</video>
```

## Forms & inputs
```html
<form action="/submit" method="post">
    <label for="email">Email</label>
    <input id="email" name="email" type="email" required>
    <input type="password" name="pw" minlength="8" required>
    <input type="number" name="qty" min="1" max="10">
    <select name="color">
        <option value="r">Red</option>
    </select>
    <textarea name="msg" rows="4"></textarea>
    <button type="submit">Send</button>
</form>
```
- Use <label for="id"> or wrap input: <label>Text <input></label>
- Validation: required, pattern, minlength, maxlength, min/max, step

## Table basics
```html
<table>
    <caption>Title</caption>
    <thead><tr><th>Col</th></tr></thead>
    <tbody><tr><td>Value</td></tr></tbody>
    <tfoot>…</tfoot>
</table>
```

## Global attributes
- id, class, style, title, hidden, data-* (custom data), tabindex, role

## ARIA & accessibility tips
- Use semantic elements and landmarks.
- Use aria-label, aria-hidden, aria-live where needed.
- Ensure keyboard focus: tabindex="0" for non-native focusable elements.
- Add visible focus styles and meaningful alt text and labels.

## Scripts
```html
<script src="app.js" defer></script>
<script src="lib.js" async></script>
<script type="module" src="main.mjs"></script>
```
- defer: execute after parsing, preserves order. async: execute as soon as ready (no order). module: ES modules.

## Metadata & SEO basics
- charset, viewport, description, canonical:
```html
<link rel="canonical" href="https://example.com/page">
<meta name="robots" content="index,follow">
```

## Performance & best practices
- Use lazy loading for images: loading="lazy"
- Minimize blocking CSS in head; load critical CSS inline when needed.
- Use responsive images (srcset/sizes).
- Prefetch or preload critical assets when necessary:
```html
<link rel="preload" href="/fonts.woff2" as="font" crossorigin>
```

## Security basics
- For external links use rel="noopener noreferrer"
- Use correct Content Security Policy on server
- Sanitize user input on server side

## HTML comments & entities
- Comment: <!-- comment -->
- Common entities: &lt; &gt; &amp; &copy; &nbsp;

## Minimal accessible page example
```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Accessible page</title>
</head>
<body>
    <header role="banner"><h1>Site</h1></header>
    <nav role="navigation"><a href="#main">Skip to content</a></nav>
    <main id="main" role="main">
        <article>
            <h2>Article title</h2>
            <p>Intro text…</p>
        </article>
    </main>
    <footer role="contentinfo">© Company</footer>
</body>
</html>
```

Keep this cheat sheet as a quick reference; expand sections with examples when you need deeper details.