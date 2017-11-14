FROM swift:4

COPY Package@swift-4.0.swift /code/Package.swift
WORKDIR /code
RUN swift package resolve
COPY ./Sources /code/Sources
COPY ./Tests /code/Tests
CMD swift test
