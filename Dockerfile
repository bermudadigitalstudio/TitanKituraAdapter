FROM swift:3.1

COPY Package.swift /code/Package.swift
WORKDIR /code
RUN swift package fetch
COPY ./Sources /code/Sources
COPY ./Tests /code/Tests
CMD swift test
