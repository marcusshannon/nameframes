module.exports = {
    theme: {},
    variants: {},
    plugins: [
        require('@tailwindcss/ui'),
    ],
    purge: {
        enabled: true,
        content: ['../lib/**/*.eex',
            '../lib/**/*.leex',
        ]
    }
}
