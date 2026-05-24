<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'Laravel') }}</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: #0f172a;
            color: #f1f5f9;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .card {
            text-align: center;
            padding: 3rem 4rem;
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 1rem;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5);
        }

        .badge {
            display: inline-block;
            font-size: 0.75rem;
            font-weight: 600;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: #38bdf8;
            background: rgba(56, 189, 248, 0.1);
            border: 1px solid rgba(56, 189, 248, 0.2);
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            margin-bottom: 1.5rem;
        }

        h1 {
            font-size: 3.5rem;
            font-weight: 800;
            background: linear-gradient(135deg, #38bdf8, #818cf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            line-height: 1.1;
            margin-bottom: 1rem;
        }

        p {
            color: #94a3b8;
            font-size: 1rem;
            margin-bottom: 2rem;
        }

        .stack {
            display: flex;
            gap: 0.5rem;
            justify-content: center;
            flex-wrap: wrap;
        }

        .tag {
            font-size: 0.75rem;
            padding: 0.25rem 0.6rem;
            background: #0f172a;
            border: 1px solid #334155;
            border-radius: 0.375rem;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">Laravel 12 · Docker Ready</div>
        <h1>Hello, World!</h1>
        <p>Tu Starter Kit está funcionando correctamente.</p>
        <div class="stack">
            <span class="tag">PHP {{ PHP_MAJOR_VERSION }}.{{ PHP_MINOR_VERSION }}</span>
            <span class="tag">Laravel {{ app()->version() }}</span>
            <span class="tag">{{ app()->environment() }}</span>
        </div>
    </div>
</body>
</html>
