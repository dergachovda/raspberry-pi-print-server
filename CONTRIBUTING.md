# Contributing to Raspberry Pi Print Server

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (Raspberry Pi model, OS version, Docker version)
- Relevant logs or error messages

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:
- Check if the enhancement has already been suggested
- Provide a clear use case
- Explain how it would benefit users
- Consider implementation complexity

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with clear messages**
6. **Push to your fork**
7. **Create a Pull Request**

## Development Guidelines

### Code Style

- **YAML/Ansible**: Use 2 spaces for indentation
- **Shell scripts**: Follow ShellCheck recommendations
- **Docker**: Follow Docker best practices
- **Documentation**: Use clear, concise language

### Testing

Before submitting a PR, ensure:
- Docker Compose configuration validates: `docker compose config`
- Ansible playbook syntax is valid: `ansible-playbook playbook.yml --syntax-check`
- Shell scripts pass shellcheck: `shellcheck deploy.sh`
- Documentation is clear and up-to-date

### Commit Messages

Follow conventional commits:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code refactoring
- `test:` for test additions/changes
- `chore:` for maintenance tasks

Example: `feat: add support for network printer discovery`

## Project Structure

```
raspberry-pi-print-server/
├── ansible/              # Ansible deployment files
│   ├── ansible.cfg      # Ansible configuration
│   ├── inventory.ini    # Host inventory template
│   └── playbook.yml     # Main deployment playbook
├── cups/                # CUPS configuration
│   ├── cupsd.conf       # Main CUPS config
│   ├── cups-files.conf  # File paths config
│   └── printers.conf    # Printer definitions
├── docs/                # Documentation
│   └── INSTALLATION.md  # Installation guide
├── docker-compose.yml   # Docker Compose config
├── Dockerfile          # CUPS container definition
├── deploy.sh           # Deployment script
├── Makefile           # Build automation
├── .env.example       # Environment variables template
└── README.md          # Main documentation
```

## Areas for Contribution

### High Priority

- Additional printer driver support
- Improved security configurations
- Better error handling
- Enhanced documentation
- Multi-architecture support (ARM32, ARM64, x86_64)

### Medium Priority

- Automated testing
- CI/CD pipeline
- Web UI improvements
- Monitoring and logging enhancements
- Network printer support

### Nice to Have

- Printer auto-discovery
- Mobile app integration
- Cloud printing support
- Multi-language documentation
- Performance optimizations

## Testing Your Changes

### Local Testing

1. Clone your fork
2. Make changes
3. Test Docker Compose:
   ```bash
   make test
   docker compose config
   ```
4. Test deployment script:
   ```bash
   ./deploy.sh deploy
   ./deploy.sh status
   ./deploy.sh logs
   ./deploy.sh stop
   ```

### Ansible Testing

Test with Ansible in check mode:
```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml --check
```

## Documentation

When adding features:
- Update README.md if user-facing
- Add detailed comments in code
- Update INSTALLATION.md if setup changes
- Include usage examples

## Questions?

- Open a discussion on GitHub
- Check existing issues and PRs
- Review documentation

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn and grow

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
