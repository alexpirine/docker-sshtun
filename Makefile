build:
	docker build . -t $(DOCKER_USERNAME)/sshtun

deploy:
	echo "$(DOCKER_PASSWORD)" | docker login -u '$(DOCKER_USERNAME)' --password-stdin
	docker push $(DOCKER_USERNAME)/sshtun
